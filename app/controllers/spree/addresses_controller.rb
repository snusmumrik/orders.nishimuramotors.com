class Spree::AddressesController < ApplicationController
  before_action :set_spree_address, only: [:show, :edit, :update, :destroy]

  # GET /spree/addresses
  # GET /spree/addresses.json
  def index
    @spree_addresses = Spree::Address.all
  end

  # GET /spree/addresses/1
  # GET /spree/addresses/1.json
  def show
  end

  # GET /spree/addresses/new
  def new
    @spree_address = Spree::Address.new
  end

  # GET /spree/addresses/1/edit
  def edit
  end

  # POST /spree/addresses
  # POST /spree/addresses.json
  def create
    @spree_address = Spree::Address.new(spree_address_params)

    respond_to do |format|
      if @spree_address.save
        format.html { redirect_to @spree_address, notice: t("activerecord.models.spree/address") + t("messages.successfully_created") }
        format.json { render :show, status: :created, location: @spree_address }
      else
        format.html { render :new }
        format.json { render json: @spree_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spree/addresses/1
  # PATCH/PUT /spree/addresses/1.json
  def update
    respond_to do |format|
      if @spree_address.update(spree_address_params)
        format.html { redirect_to @spree_address, notice: t("activerecord.models.spree/address") + t("messages.successfully_updated") }
        format.json { render :show, status: :ok, location: @spree_address }
      else
        format.html { render :edit }
        format.json { render json: @spree_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spree/addresses/1
  # DELETE /spree/addresses/1.json
  def destroy
    @spree_address.destroy
    respond_to do |format|
      format.html { redirect_to spree_addresses_url, notice: t("activerecord.models.spree/address") + t("messages.successfully_destroyed") }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spree_address
      @spree_address = Spree::Address.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spree_address_params
      params[:spree_address]
    end
end
