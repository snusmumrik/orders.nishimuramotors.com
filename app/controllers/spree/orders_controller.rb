# -*- coding: utf-8 -*-
class Spree::OrdersController < ApplicationController
  before_action :set_spree_order, only: [:show, :edit, :update, :destroy]

  # GET /spree/orders
  # GET /spree/orders.json
  def index
    @spree_orders = Spree::Order.order("created_at DESC").page params[:page]
    begin
      payment_array = ActiveRecord::Base.connection.select_all("select * from spree_payments where order_id in (#{@spree_orders.pluck(:id).join(',')})").to_hash
      @payments = Hash.new
      payment_array.each do |p|
        @payments.store(p["order_id"], p["state"])
      end

      @line_items = Hash.new
      @spree_orders.each do |spree_order|
        hash = Hash.new
        spree_order.line_items.each do |item|
          hash.store(item.variant_id, {quantity: item.quantity, price: item.price})
        end
        @line_items.store(spree_order.id, hash)
      end
    rescue
    end
  end

  # GET /spree/orders/1
  # GET /spree/orders/1.json
  def show
    @line_items = Hash.new
    @spree_order.line_items.each do |item|
      @line_items.store(item.variant_id, {quantity: item.quantity, price: item.price})
    end

    respond_to do |format|
      format.html # show.html.erb
      format.pdf do
        pdf = OrderPDF.new(@spree_order)
        pdf.font "vendor/fonts/ipaexm.ttf"

        send_data pdf.render,
          filename:    "#{@spree_order.id}.pdf",
          type:        "application/pdf",
          disposition: "inline"
      end
    end
  end

  # GET /spree/orders/new
  def new
    @spree_order = Spree::Order.new
  end

  # GET /spree/orders/1/edit
  def edit
  end

  # POST /spree/orders
  # POST /spree/orders.json
  def create
    @spree_order = Spree::Order.new(spree_order_params)

    respond_to do |format|
      if @spree_order.save
        format.html { redirect_to @spree_order, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @spree_order }
      else
        format.html { render :new }
        format.json { render json: @spree_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spree/orders/1
  # PATCH/PUT /spree/orders/1.json
  def update
    respond_to do |format|
      if @spree_order.update(spree_order_params)
        format.html { redirect_to @spree_order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @spree_order }
      else
        format.html { render :edit }
        format.json { render json: @spree_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spree/orders/1
  # DELETE /spree/orders/1.json
  def destroy
    @spree_order.destroy
    respond_to do |format|
      format.html { redirect_to spree_orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spree_order
      @spree_order = Spree::Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spree_order_params
      params[:spree_order]
    end
end
