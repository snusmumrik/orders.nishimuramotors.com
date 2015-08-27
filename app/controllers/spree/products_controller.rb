class Spree::ProductsController < ApplicationController
  before_action :set_spree_product, only: [:show, :edit, :update, :destroy]

  # GET /spree/products
  # GET /spree/products.json
  def index
    @spree_products = Spree::Product.all
  end

  # GET /spree/products/1
  # GET /spree/products/1.json
  def show
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
        format.html { redirect_to @spree_product, notice: 'Product was successfully created.' }
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
        format.html { redirect_to @spree_product, notice: 'Product was successfully updated.' }
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
      format.html { redirect_to spree_products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spree_product
      @spree_product = Spree::Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spree_product_params
      params[:spree_product]
    end
end
