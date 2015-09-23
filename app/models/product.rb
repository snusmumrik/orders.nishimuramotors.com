# -*- coding: utf-8 -*-
require "mechanize"
require "csv"
require "net/http"

class Product < ActiveRecord::Base
  def self.search_index(url = "http://nbsj.ocnk.net")
    agent = Mechanize.new
    page = agent.get(url)

    # page.search("ul.subcategories").each do |ul|
    #   ul.search("li").each do |li|
    #     product_list_page_link = li.at("a").attr("href")
    #     p "PRODUCT LIST PAGE: #{product_list_page_link}"

    #     self.product_search(product_list_page_link)
    #   end
    # end

    page.search("li.parent_category").each do |li|
      next unless li.at("div.parentcategory a")
      parentcategory = li.at("div.parentcategory a").text
      p parentcategory

      li.search("ul.subcategories li").each do |li|
        subcategories = li.at("a").text
        p subcategories
        product_list_page_link = li.at("a").attr("href")
        p "PRODUCT LIST PAGE: #{product_list_page_link}"

        self.product_search(parentcategory, subcategories, product_list_page_link)
      end
    end
  end

  private
  def self.product_search(parentcategory, subcategories, url, root= "http://nbsj.ocnk.net")
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

      p "PARENTCATEGORY: #{parentcategory}, SUBCATEGORIES: #{subcategories}, IMAGE:#{image_url}, NAME:#{name}, MODEL NUMBER:#{model_number}, PRICE:#{price}, DESCRIPTION:#{description}, SOLD OUT:#{sold_out}"

      array = [parentcategory, subcategories, name, model_number, description, price, image_url, sold_out]
      path = "public/products.csv"

      CSV.open(path, 'a') do |writer|
        writer << array
      end
    end

    if next_page
      p "NEXT: #{next_page}"
      self.product_search(parentcategory, subcategories, "#{root}/#{next_page}")
    end
  end
end
