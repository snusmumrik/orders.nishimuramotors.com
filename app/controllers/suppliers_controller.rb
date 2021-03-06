class SuppliersController < ApplicationController
  before_action :set_supplier, only: [:show, :edit, :update, :destroy]
  before_action :get_spree_product, only: [:new, :create, :edit, :update]

  # GET /suppliers
  # GET /suppliers.json
  def index
    @suppliers = Supplier.all
  end

  # GET /suppliers/1
  # GET /suppliers/1.json
  def show
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new
  end

  # GET /suppliers/1/edit
  def edit
  end

  # POST /suppliers
  # POST /suppliers.json
  def create
    @supplier = Supplier.new(supplier_params)

    respond_to do |format|
      if @supplier.save
        if session[:previous_page]
          redirect_path = session[:previous_page]
        else
          redirect_path = spree_products_path
        end
        format.html { redirect_to reditect_path, notice: t("activerecord.models.supplier") + t("messages.created") }
        format.json { render :show, status: :created, location: @supplier }
      else
        format.html { render :new }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /suppliers/1
  # PATCH/PUT /suppliers/1.json
  def update
    respond_to do |format|
      if @supplier.update(supplier_params)
        if session[:previous_page]
          redirect_path = session[:previous_page]
        else
          redirect_path = spree_products_path
        end
        format.html { redirect_to redirect_path, notice: t("activerecord.models.supplier") + t("messages.updated") }
        format.json { render :show, status: :ok, location: @supplier }
      else
        format.html { render :edit }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /suppliers/1
  # DELETE /suppliers/1.json
  def destroy
    @supplier.destroy
    respond_to do |format|
      format.html { redirect_to suppliers_url, notice: t("activerecord.models.supplier") + t("messages.successfully_destroyed") }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_supplier
      @supplier = Supplier.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def supplier_params
      params.require(:supplier).permit(:spree_product_id, :ngsj, :bikepartscenter, :nbstire, :iiparts, :amazon, :asin, :rakuten, :yahoo)
    end

  def get_spree_product
    @spree_product = Spree::Product.find(params[:id])
  end
end
