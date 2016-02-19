# -*- coding: utf-8 -*-
require "mechanize"
require "selenium-webdriver"

class PurchasesController < ApplicationController
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]
  before_action :set_purchases, only: [:index, :create_orders]
  before_action :set_accounts, only: [:create_orders]

  # GET /purchases
  # GET /purchases.json
  def index
    set_purchases
    @purchase = Purchase.new
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
    spree_order = ActiveRecord::Base.connection.select_one("select * from spree_line_items a left join spree_variants b on a.variant_id = b.id left join purchases c on a.order_id = c.spree_order_id where b.product_id = #{@purchase.spree_product_id} and c.amount is null")
    @purchase.spree_order_id = spree_order["order_id"] if spree_order

    respond_to do |format|
      if spree_order && @purchase.save
        format.html { redirect_to purchases_path, notice: t("activerecord.models.purchase") + t("messages.successfully_created") }
        format.json { render :show, status: :created, location: @purchase }
      else
        format.html { redirect_to purchases_path, alert: t("activerecord.models.purchase") + t("messages.not_created") }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchases/1
  # PATCH/PUT /purchases/1.json
  def update
    respond_to do |format|
      if @purchase.update(purchase_params)
        format.html { redirect_to @purchase, notice: t("activerecord.models.purchase") + t("messages.successfully_updated") }
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
      format.html { redirect_to purchases_url, notice: t("activerecord.models.purchase") + t("messages.successfully_destroyed") }
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

  def set_purchases
    @purchase_hash = Hash.new {|hash, key| hash[key] = 0}
    @spree_orders = Spree::Order.where(["shipment_state = ?", "ready"]).order("created_at DESC")# .page params[:page]

    unless @spree_orders.blank?
      line_items_array = ActiveRecord::Base.connection.select_all("select * from spree_orders a left join spree_line_items b on a.id = b.order_id left join spree_variants c on b.variant_id = c.id where a.payment_state = 'paid' and a.id in (#{@spree_orders.pluck(:id).join(',')})").to_hash
      product_array = Array.new
      @quantity_hash = Hash.new {|hash, key| hash[key] = 0}

      line_items_array.each do |l|
        product_array << l["product_id"]
        @quantity_hash.store(l["product_id"], @quantity_hash[l["product_id"]] += l["quantity"].to_i)
      end
      @spree_products = Spree::Product.includes(:price).where(["id in (?)", product_array.sort.uniq])
      purchase_array = ActiveRecord::Base.connection.select_all("select * from purchases where spree_order_id in (#{@spree_orders.pluck(:id).join(',')})").to_hash
      purchase_array.each do |p|
        @purchase_hash[p["spree_product_id"]] += p["amount"]
      end

      @supplier_hash = Hash.new
      suppliers = Supplier.where(["spree_product_id in (?)", product_array.sort.uniq]).inject(Hash.new){|hash, s| hash[s.spree_product_id] = s; hash }
      @spree_products.each do |p|
        # supplier = Supplier.where(["spree_product_id = ?", spree_product.id]).first
        supplier = suppliers[p.id]

        case p.price.lowest_price
        when p.price.ngsj
          hash = {name: t("activerecord.attributes.supplier.ngsj"), url: supplier.ngsj}
          @supplier_hash.store(p.id, hash)
        when p.price.bikepartscenter
          hash = {name: t("activerecord.attributes.supplier.bikepartscenter"), url: supplier.bikepartscenter}
          @supplier_hash.store(p.id, hash)
        when p.price.iiparts
          hash = {name: t("activerecord.attributes.supplier.iiparts"), url: supplier.iiparts}
          @supplier_hash.store(p.id, hash)
        when p.price.nbstire
          hash = {name: t("activerecord.attributes.supplier.nbstire"), url: supplier.nbstire}
          @supplier_hash.store(p.id, hash)
        when p.price.amazon
          hash = {name: t("activerecord.attributes.supplier.amazon"), url: supplier.amazon}
          @supplier_hash.store(p.id, hash)
        when p.price.rakuten
          hash = {name: t("activerecord.attributes.supplier.rakuten"), url: supplier.rakuten}
          @supplier_hash.store(p.id, hash)
        when p.price.yahoo
          hash = {name: t("activerecord.attributes.supplier.yahoo"), url: supplier.yahoo}
          @supplier_hash.store(p.id, hash)
        end
      end
    end
  end

  def create_orders
    set_purchases
    set_accounts

    @suppliers = @supplier_hash.inject(Hash.new{|hash, key| hash[key] = Array.new}){|hash, s| hash[s[1][:name]] << {spree_product_id: s[0], url: s[1][:url]}; hash }
    @suppliers.each do |s|
      supplier = s[0]
      puts supplier

      driver = Selenium::WebDriver.for :chrome

      case s[0]
      when "バイクパーツセンター"
        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "purchase_qty").find_element(:xpath, "select")).select_by(:value, @quantity_hash[hash[:spree_product_id]].to_s)
          driver.find_element(:id, "submit_cart_input_btn").click
        end

        driver.find_element(:name, "go-next").click
        driver.find_element(:id, "login_email").send_keys(@accounts[supplier].identifier)
        driver.find_element(:id, "login_password").send_keys(@accounts[supplier].password)
        driver.find_element(:id, "login").click

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "pay_procedure").click
        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click


        #
        #Mechanize
        #

        # Mechanize.start do |agent|
        #   s[1].each do |hash|
        #     url = hash[:url]
        #     puts url

        #     page = agent.get(url)
        #     form = page.form_with(id: "productadd")
        #     select = form.field_with(id: /cart_addquantity_/){|list|
        #       list.option_with(text: @quantity_hash[hash[:spree_product_id]].to_s).select
        #     }
        #     button = form.button_with(id: "submit_cart_input_btn")
        #     agent.submit(form, button)
        #   end
        #   cart_page = agent.get("http://nbsj.ocnk.net/cart")
        #   cart_form = cart_page.form_with(id: "register")
        #   cart_button = cart_form.button_with(value: "レジに進む")

        #   cart_page2 = agent.submit(cart_form, cart_button)
        #   cart_form2 = cart_page2.form_with(id: "register")
        #   cart_form2.field_with(id: "login_email").value = @accounts[supplier].identifier
        #   cart_form2.field_with(id: "login_password").value = Account.decrypt(@accounts[supplier].password)
        #   cart_button2 = cart_form2.button_with(value: "ログイン")

        #   cart_page3 = agent.submit(cart_form2, cart_button2)
        #   cart_form3 = cart_page3.form_with(id: "register")
        #   cart_button3 = cart_form3.button_with(value: "次へ")

        #   cart_page4 = agent.submit(cart_form3, cart_button3)
        #   cart_form4 = cart_page4.form_with(id: "register")
        #   cart_button4 = cart_form4.button_with(value: "次へ")

        #   cart_page5 = agent.submit(cart_form4, cart_button4)
        #   cart_form5 = cart_page5.form_with(id: "register")
        #   cart_form5.radiobutton_with(name: "pay_procedure").check
        #   cart_button5 = cart_form5.button_with(value: "次へ")

        #   cart_page6 = agent.submit(cart_form5, cart_button5)

        #   cart_form6 = cart_page6.form_with(id: "register")
        #   cart_button6 = cart_form6.button_with(value: "購入する")
        #   # agent.submit(cart_form6, cart_button6)
        # end
      when "バイクパーツセンター タイヤ専門館"
        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "purchase_qty").find_element(:xpath, "select")).select_by(:value, @quantity_hash[hash[:spree_product_id]].to_s)
          driver.find_element(:id, "submit_cart_input_btn").click
        end

        driver.find_element(:name, "go-next").click
        driver.find_element(:id, "login_email").send_keys(@accounts[supplier].identifier)
        driver.find_element(:id, "login_password").send_keys(@accounts[supplier].password)
        driver.find_element(:id, "login").click

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "pay_procedure").click
        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click
      when "NBS"
        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          quantity = driver.find_element(:name, "product_num")
          quantity.clear
          quantity.send_keys(@quantity_hash[hash[:spree_product_id]])
          driver.find_element(:name, "submit").click
        end

        driver.find_element(:class, "btn_regi").click
        driver.find_element(:name, "login_email").send_keys(@accounts[supplier].identifier)
        driver.find_element(:name, "login_password").send_keys(@accounts[supplier].password)
        driver.find_element(:class, "button").find_element(:class, "button").click

        driver.find_element(:class, "btn_next").click

        driver.find_element(:class, "btn_next").click

        driver.find_element(:class, "btn_next").click

        driver.find_element(:class, "btn_end").click
      when "NBS タイヤ専門館"
        driver.navigate.to("http://nbs-tire.ocnk.net/")
        driver.find_element(:name, "email").send_keys(@accounts[supplier].identifier)
        driver.find_element(:name, "password").send_keys(@accounts[supplier].password)
        driver.find_element(:id, "side_login_submit").click

        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "purchase_qty").find_element(:xpath, "select")).select_by(:value, @quantity_hash[hash[:spree_product_id]].to_s)
          driver.find_element(:id, "submit_cart_input_btn").click
        end

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "pay_procedure").click
        driver.find_element(:name, "go-next").click

        driver.find_element(:name, "go-next").click
      when "amazon"
        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          Selenium::WebDriver::Support::Select.new(driver.find_element(:name, "quantity")).select_by(:value, @quantity_hash[hash[:spree_product_id]].to_s)
          driver.find_element(:id, "submit.add-to-cart").click
        end

        driver.find_element(:id, "hlb-ptc-btn-native").click
        driver.find_element(:id, "ap_email").send_keys(@accounts[supplier].identifier)
        driver.find_element(:id, "ap_password").send_keys(@accounts[supplier].password)
        driver.find_element(:id, "signInSubmit").click

        driver.find_element(:name, "placeYourOrder1").click
      when "楽天"
        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          quantity = driver.find_element(:name, "units")
          quantity.clear
          quantity.send_keys(@quantity_hash[hash[:spree_product_id]])
          driver.find_element(:class, "rCartBtn").click
        end

        driver.find_element(:name, "submit").click
        driver.find_element(:name, "u").send_keys(@accounts[supplier].identifier)
        driver.find_element(:name, "p").send_keys(@accounts[supplier].password)
        driver.find_element(:id, "login_submit").click

        driver.find_element(:name, "commit").click
      when "ヤフー"
        s[1].each do |hash|
          url = hash[:url]
          puts url

          driver.navigate.to(url)
          quantity = driver.find_element(:name, "vwquantity")
          quantity.clear
          quantity.send_keys(@quantity_hash[hash[:spree_product_id]])
          driver.find_element(:class, "elCartButton").click
        end

        driver.find_element(:class, "dcEnterButton").click
        driver.find_element(:id, "username").send_keys(@accounts[supplier].identifier)
        driver.find_element(:id, "passwd").send_keys(@accounts[supplier].password)
        driver.find_element(:id, ".save").click

        driver.find_element(:id, "toReview").click


        driver.find_element(:id, "removeCheck").click
        driver.find_element(:name, "rate-later").click
        driver.find_element(:name, "merchant-letter").click
        driver.find_element(:name, "newsclip").click

        driver.find_element(:name, "decide").click
      end
      driver.quit
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def set_accounts
    @accounts = Account.all.inject(Hash.new){|hash, a| hash[a.supplier] = a; hash}
    @accounts.each do |a|
      a[1].password = Account.decrypt(a[1].password)
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_params
    params.require(:purchase).permit(:spree_product_id, :spree_order_id, :amount)
  end
end
