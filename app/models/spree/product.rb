# -*- coding: utf-8 -*-
require "mechanize"
require "csv"
require "net/http"

class Spree::Product < ActiveRecord::Base
  has_many :product_option_types, dependent: :destroy, inverse_of: :product
  has_many :option_types, through: :product_option_types
  has_many :product_properties, dependent: :destroy, inverse_of: :product
  has_many :properties, through: :product_properties

  has_many :classifications, dependent: :delete_all, inverse_of: :product
  has_many :taxons, through: :classifications

  has_many :product_promotion_rules, class_name: 'Spree::ProductPromotionRule'
  has_many :promotion_rules, through: :product_promotion_rules, class_name: 'Spree::PromotionRule'

  belongs_to :tax_category, class_name: 'Spree::TaxCategory'
  belongs_to :shipping_category, class_name: 'Spree::ShippingCategory', inverse_of: :products

  has_one :master,
  -> { where is_master: true },
  inverse_of: :product,
  class_name: 'Spree::Variant'

  has_many :variants,
  -> { where(is_master: false).order("#{::Spree::Variant.quoted_table_name}.position ASC") },
  inverse_of: :product,
  class_name: 'Spree::Variant'

  has_many :variants_including_master,
  -> { order("#{::Spree::Variant.quoted_table_name}.position ASC") },
  inverse_of: :product,
  class_name: 'Spree::Variant',
  dependent: :destroy

  has_many :prices, -> { order('spree_variants.position, spree_variants.id, currency') }, through: :variants

  has_many :stock_items, through: :variants_including_master

  has_many :line_items, through: :variants_including_master
  has_many :orders, through: :line_items

  has_one :supplier, foreign_key: :spree_product_id
  has_one :price, foreign_key: :spree_product_id

  paginates_per 10

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

      image_url = nil
      name = nil
      model_number = nil
      price = nil
      description = nil

      li.search("a").each_with_index do |a, i|
        case i
        when 0
          image_url = a.at("img").attr("src")
        when 1
          name = a.at("span.goods_name").text
          model_number = a.at("span.model_number_value").text
        end
      end

      price = li.at("p.selling_price span").text if li.at("p.selling_price span")
      description = li.at("p.item_desc").text.strip if li.at("p.item_desc")

      sold_out = true
      li.at(".add_cart").search("form").each do |form|
        if form.at("input[type='submit']").attr("value") == "カートに入れる"
          sold_out = false
        end
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
