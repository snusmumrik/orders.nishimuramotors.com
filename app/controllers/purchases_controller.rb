class PurchasesController < ApplicationController
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]

  # GET /purchases
  # GET /purchases.json
  def index
    @spree_orders = Spree::Order.where(["shipment_state != ?", "shipped"]).order("created_at DESC").page params[:page]

    begin
      payment_array = ActiveRecord::Base.connection.select_all("select * from spree_payments where order_id in (#{@spree_orders.pluck(:id).join(',')})").to_hash
      @payments = Hash.new
      payment_array.each do |p|
        @payments.store(p["order_id"], p["state"])
      end

      line_items_array = ActiveRecord::Base.connection.select_all("select * from spree_payments left join spree_line_items on spree_payments.order_id = spree_line_items.order_id left join spree_variants on spree_line_items.variant_id = spree_variants.id where spree_payments.state = 'completed' and spree_line_items.order_id in (#{@spree_orders.pluck(:id).join(',')}) and spree_payments.state = 'completed'").to_hash

      product_array = Array.new
      @quantity_hash = Hash.new {|hash, key| hash[key] = 0}

      line_items_array.each do |l|
        product_array << l["product_id"]
        @quantity_hash.store(l["product_id"], @quantity_hash[l["product_id"]] += l["quantity"].to_i)
      end
      @spree_products = Spree::Product.where(["id in (?)", product_array.sort.uniq])

      @supplier_hash = Hash.new
      # suppliers = Supplier.where(["spree_product_id in (?)", product_array.sort.uniq])
      @spree_products.each do |spree_product|
        supplier = Supplier.where(["spree_product_id = ?", spree_product.id]).first
        if spree_product.price.lowest_price == spree_product.price.ngsj
          hash = {name: t("activerecord.attributes.supplier.ngsj"), url: supplier.ngsj}
          @supplier_hash.store(spree_product.id, hash)
        elsif spree_product.price.lowest_price == spree_product.price.iiparts
          hash = {name: t("activerecord.attributes.supplier.iiparts"), url: supplier.iiparts}
          @supplier_hash.store(spree_product.id, hash)
        elsif spree_product.price.lowest_price == spree_product.price.amazon
          hash = {name: t("activerecord.attributes.supplier.amazon"), url: supplier.amazon}
          @supplier_hash.store(spree_product.id, hash)
        elsif spree_product.price.lowest_price == spree_product.price.rakuten
          hash = {name: t("activerecord.attributes.supplier.rakuten"), url: Supplier.get_rakuten_link(supplier.rakuten)}
          @supplier_hash.store(spree_product.id, hash)
        elsif spree_product.price.lowest_price == spree_product.price.yahoo
          hash = {name: t("activerecord.attributes.supplier.yahoo"), url: Supplier.get_yahoo_link(supplier.yahoo)}
          @supplier_hash.store(spree_product.id, hash)
        end
      end
    rescue
    end
  end

  # GET /purchases/1
  # GET /purchases/1.json
  def show
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
  end

  # GET /purchases/1/edit
  def edit
  end

  # POST /purchases
  # POST /purchases.json
  def create
    @purchase = Purchase.new(purchase_params)

    respond_to do |format|
      if @purchase.save
        format.html { redirect_to @purchase, notice: 'Purchase was successfully created.' }
        format.json { render :show, status: :created, location: @purchase }
      else
        format.html { render :new }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchases/1
  # PATCH/PUT /purchases/1.json
  def update
    respond_to do |format|
      if @purchase.update(purchase_params)
        format.html { redirect_to @purchase, notice: 'Purchase was successfully updated.' }
        format.json { render :show, status: :ok, location: @purchase }
      else
        format.html { render :edit }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchases/1
  # DELETE /purchases/1.json
  def destroy
    @purchase.destroy
    respond_to do |format|
      format.html { redirect_to purchases_url, notice: 'Purchase was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def update_prices
    @spree_orders = Spree::Order.where(["shipment_state != ?", "shipped"]).order("created_at DESC").page params[:page]

    begin
      line_items_array = ActiveRecord::Base.connection.select_all("select * from spree_line_items left join spree_variants on spree_line_items.variant_id = spree_variants.id where order_id in (#{@spree_orders.pluck(:id).join(',')})").to_hash

      product_array = Array.new

      line_items_array.each do |l|
        product_array << l["product_id"]
      end
      @spree_products = Spree::Product.where(["id in (?)", product_array.sort.uniq])
    rescue
    end

    @spree_products.each do |spree_product|
      Price.get_price(spree_product)
    end
    redirect_to purchases_path
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_params
    params[:purchase]
  end
end
