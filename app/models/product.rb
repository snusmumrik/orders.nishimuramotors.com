# -*- coding: utf-8 -*-
require "mechanize"
require "csv"
require "net/http"

class Product < ActiveRecord::Base
  def self.index_search(url = "http://nbsj.ocnk.net")
    agent = Mechanize.new
    page = agent.get(url)
    page.search("ul.subcategories").each do |ul|
      ul.search("li").each do |li|
        product_list_page_link = li.at("a").attr("href")
        p "PRODUCT LIST PAGE: #{product_list_page_link}"

        self.product_search(product_list_page_link)
      end
    end
  end

  def self.update_price
    Spree::Product.all.each do |product|
      price = Price.where(["spree_product_id = ?", product.id]).first
      array = Array.new
      array << price.ngsj unless price.ngsj.nil?
      array << price.iiparts unless price.iiparts.nil?
      array << price.amazon unless price.amazon.nil?
      array << price.rakuten unless price.rakuten.nil?
      array << price.yahoo unless price.yahoo.nil?
      array.sort

      low = array.first
      high = array.last
      percentage = Profit.last.try(:percentage) || 0.5

      if !low.nil? && !high.nil?
        product.price = low + (high - low) * percentage
      elsif !low.nil?
        product.price = low * 1.3
      end

      if array.size == 0
        product.avilable_on = nil
      end

      p product.price.to_i
      product.save
    end
  end

  private
  def self.product_search(url, root= "http://nbsj.ocnk.net")
    agent = Mechanize.new
    product_list_page = agent.get(url)

    if product_list_page.at("#pagertop a.to_next_page")
      next_page = product_list_page.at("#pagertop a.to_next_page").attr("href")
      p "NEXT PAGE FOUND: #{next_page}"
    else
      next_page = nil
    end

    product_list_page.search("ul.layout160 li").each_with_index do |li, i|
      p i

      detail_link = li.at(".item_data a").attr("href")
      p detail_link

      detail_page = agent.get(detail_link)

      image_url = detail_page.at(".global_photo a").attr("href")
      name = detail_page.at(".goods_name").text
      model_number = detail_page.at(".model_number_value").text
      price = detail_page.at(".selling_price .figure").text
      price = price.sub("円", "") if price


      if detail_page.at("#submit_cart_input_btn")
        sold_out = false
      else
        sold_out = true
      end

      if detail_page.at(".item_desc_text")
        description = detail_page.at(".item_desc_text").text.strip
      else
        description = ""
      end

      p "IMAGE:#{image_url}, NAME:#{name}, MODEL NUMBER:#{model_number}, PRICE:#{price}, DESCRIPTION:#{description}, SOLD OUT:#{sold_out}"

      array = [name, model_number, description, price, image_url, sold_out]
      path = "public/products.csv"

      CSV.open(path, 'a') do |writer|
        writer << array
      end
    end

    if next_page
      p "NEXT: #{next_page}"
      self.product_search("#{root}/#{next_page}")
    end
  end
end
