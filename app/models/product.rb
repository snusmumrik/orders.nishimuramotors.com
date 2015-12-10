# -*- coding: utf-8 -*-
require "mechanize"
require "csv"
require "net/http"

class Product < ActiveRecord::Base
  def self.search_index(url = "http://nbsj.ocnk.net")
    agent = Mechanize.new
    page = agent.get(url)

    page.search("li.parent_category").each do |li|
      if li.at("div.parentcategory a")
        parentcategory = li.at("div.parentcategory a").text
        p parentcategory

        li.search("ul.subcategories li").each do |li|
          subcategories = li.at("a").text
          p subcategories
          product_list_page_link = li.at("a").attr("href")
          p "PRODUCT LIST PAGE: #{product_list_page_link}"
          self.product_search(parentcategory, subcategories, product_list_page_link)
        end
      elsif li.at("div.maincategory a")
        parentcategory = li.at("div.maincategory a").text
        p parentcategory
        subcategories = nil

        product_list_page_link = li.at("div.maincategory a").attr("href")
        p "PRODUCT LIST PAGE: #{product_list_page_link}"
        self.product_search(parentcategory, subcategories, product_list_page_link)
      end
    end

    page.search("ul.pickupcategory_list li").each do |li|
      parentcategory = li.at("a").text
      p parentcategory

      subcategories = parentcategory
      product_list_page_link = li.at("a").attr("href")
      p "PRODUCT LIST PAGE: #{product_list_page_link}"

      self.product_search(parentcategory, subcategories, product_list_page_link)
    end
  end

  def self.search_index_for_tyre(url = "http://www.bike-partscenter.com")
    agent = Mechanize.new
    page = agent.get(url)
    page.search(".category_list>ul>li").each do |li|
      parentcategory = li.search("span.mcategory a").text

      if li.search("ul>li").size > 0
        li.search("ul>li").each do |li2|
          subcategories = li2.at("a").text
          product_list_page_link = li2.at("a").attr("href")

          p "PARENTCATEGORY: #{parentcategory}, SUBCATEGORIES: #{subcategories}, PRODUCT_LIST_PAGE_LINK: #{product_list_page_link}"
          if product_list_page_link
            self.product_search_for_tyre(parentcategory, subcategories, product_list_page_link)
          end
        end
      else
        product_list_page_link = li.search("span.mcategory a").attr("href")

        p "PARENTCATEGORY: #{parentcategory}, PRODUCT_LIST_PAGE_LINK: #{product_list_page_link}"
        if product_list_page_link
          self.product_search_for_tyre(parentcategory, nil, product_list_page_link) rescue nil
        end
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
      name = detail_page.at(".goods_name").text.strip
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

  def self.product_search_for_tyre(parentcategory, subcategories, url, root= "http://www.bike-partscenter.com")
    agent = Mechanize.new
    product_list_page = agent.get(url)

    product_list_page.search(".list_table_middle").each_with_index do |div, i|
      p i

      detail_link = div.at("h2 a").attr("href")
      p detail_link

      detail_page = agent.get(detail_link)

      image_url = detail_page.at(".main_image_item_box").attr("href")
      name = detail_page.at(".item_name").text.strip
      model_number = detail_page.at(".model_number").text
      price = detail_page.at("#pricech").text
      price = price.sub("円", "") if price

      if detail_page.at("#submit_cart_input_btn")
        sold_out = false
      else
        sold_out = true
      end

      if detail_page.at(".detail_item_text div")
        description = detail_page.at(".detail_item_text.detail_desc_box div").text.strip
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
  end
end
