class Spree::ProductsController < ApplicationController
  before_action :set_spree_product, only: [:show, :edit, :update, :destroy, :update_price]

  # GET /spree/products
  # GET /spree/products.json
  def index
    if params[:category].blank?
      if params[:keyword].blank?
        @spree_products = Spree::Product.includes(:price, :supplier).page params[:page]
      else
        @spree_products = Spree::Product.includes(:price, :supplier).where(["name LIKE ?", "%#{params[:keyword]}%"]).page params[:page]
      end

      @price_hash = Price.where(["spree_product_id in (?)", @spree_products.pluck(:id)]).inject(Hash.new){|h, p| h.store(p.spree_product_id, p); h}
      @supplier_hash = Supplier.where(["spree_product_id in (?)", @spree_products.pluck(:id)]).inject(Hash.new){|h, s| h.store(s.spree_product_id, s); h}

      @lowest_price_hash = Hash.new
      prices = Price.where(["spree_product_id in (?)", @spree_products.pluck(:id)])
      prices.each do |p|
        @lowest_price_hash.store(p.id, p.lowest_price)
      end
    else
      if params[:keyword].blank?
        spree_products = Spree::Product.find_by_sql(["SELECT a.* FROM spree_products a LEFT JOIN spree_products_taxons b ON a.id = b.product_id  WHERE b.taxon_id = ?", params[:category]])
      else
        spree_products = Spree::Product.find_by_sql(["SELECT a.* FROM spree_products a LEFT JOIN spree_products_taxons b ON a.id = b.product_id WHERE b.taxon_id = ? AND a.name LIKE ?", params[:category], "%#{params[:keyword]}%"])
      end

      @spree_products = Kaminari.paginate_array(spree_products).page params[:page]
      ids = @spree_products.inject(Array.new){|a, p| a << p.id; a}
      @price_hash = Price.where(["spree_product_id in (?)", ids]).inject(Hash.new){|h, p| h.store(p.spree_product_id, p); h}
      @supplier_hash = Supplier.where(["spree_product_id in (?)", ids]).inject(Hash.new){|h, s| h.store(s.spree_product_id, s); h}

      @lowest_price_hash = Hash.new
      @price_hash.each do |p|
        @lowest_price_hash.store(p[0], p[1].lowest_price)
      end
    end

    @categories = ActiveRecord::Base.connection.select_all("select * from spree_taxon_translations where id in (1,2,3,4,5,6,7,8,241,242,243,244,245,246,247,248,252,253,254,255,256,257,258,260)").inject(Array.new){|a, c| a << [c["name"], c["id"]]; a}

    session[:previous_page] = request.original_url
  end

  # GET /spree/products/1
  # GET /spree/products/1.json
  def show
    @price = Price.where(["spree_product_id = ?", @spree_product.id]).first
  end

  # GET /spree/products/new
  def new
    @spree_product = Spree::Product.new
  end

  # GET /spree/products/1/edit
  def edit
  end

  # POST /spree/products
  # POST /spree/products.json
  def create
    @spree_product = Spree::Product.new(spree_product_params)

    respond_to do |format|
      if @spree_product.save
        format.html { redirect_to @spree_product, notice: t("activerecord.models.spree/product") + t("messages.successfully_created") }
        format.json { render :show, status: :created, location: @spree_product }
      else
        format.html { render :new }
        format.json { render json: @spree_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spree/products/1
  # PATCH/PUT /spree/products/1.json
  def update
    respond_to do |format|
      if @spree_product.update(spree_product_params)
        format.html { redirect_to request.referrer, notice: t("activerecord.models.spree/spree/product") + t("messages.updated") }
        format.json { render :show, status: :ok, location: @spree_product }
      else
        format.html { render :edit }
        format.json { render json: @spree_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spree/products/1
  # DELETE /spree/products/1.json
  def destroy
    @spree_product.destroy
    respond_to do |format|
      format.html { redirect_to spree_products_url, notice: t("activerecord.models.spree/product") + t("messages.successfully_destroyed") }
      format.json { head :no_content }
    end
  end

  def update_prices
    Spree::Product.where(["available_on is not null"]).find_each(batch_size: 10) do |spree_product|
      Price.get_price(spree_product)
    end
    redirect_to spree_products_path
  end

  def update_price
    Price.get_price(@spree_product)
    redirect_to request.referrer
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spree_product
      @spree_product = Spree::Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spree_product_params
      params[:spree_product].permit(:available_on)
    end
end
