# -*- coding: utf-8 -*-
require "mechanize"

class Price < ActiveRecord::Base
  belongs_to :spree_product

  def self.get_prices
    Spree::Product.all.each do |p|
      Price.get_price(p)
    end
  end

  def self.get_price(product)
    name = product.name.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z')
    p "NAME: #{name}"

    /([0-9a-zA-Z-]+)/ =~ name
    if $1
      keyword = $1
    else
      keyword = name
    end
    p "KEYWORD: #{keyword}"

    search_urls = ["http://nbsj.ocnk.net/product-list?keyword=#{keyword}&order=asc",
                   "http://11parts.shop-pro.jp/?mode=srh&cid=&keyword=#{keyword}&sort=p",
                   "http://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=カタカナ&url=node%3D2045198051&field-keywords=#{name.gsub(/(保証付き|１年間保証付き|【液入充電済】|【液付属】)/, '')}",
                   "http://search.rakuten.co.jp/search/inshop-mall/#{keyword}/-/f.1-p.1-s.2-sf.0-sid.229933-st.A-v.2",
                   "http://store.shopping.yahoo.co.jp/bike-parts-center/search.html?p=#{keyword}&X=2"]

    if supplier = Supplier.where(["spree_product_id = ?", product.id]).first
      search_urls[0] = supplier.ngsj if supplier.ngsj
      search_urls[1] = supplier.iiparts if supplier.iiparts
      search_urls[2] = supplier.amazon if supplier.amazon
      search_urls[3] = supplier.rakuten if supplier.rakuten
      search_urls[4] = supplier.yahoo if supplier.yahoo
    else
      supplier = Supplier.new
      supplier.spree_product_id = product.id
    end

    unless price = Price.where(["spree_product_id = ?", product.id]).first
      price = Price.new
      price.spree_product_id = product.id
    end

    agent = Mechanize.new
    search_urls.each_with_index do |url, i|
      p "#{i}: #{url}"

      begin
        page = agent.get(url) unless i == 2
        case i
        when 0
          if li = page.at("ul.layout160 li")
            detail_url = page.at("div.item_data a").attr("href")
            detail_page = agent.get(detail_url)
            p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
            p p

            # p = li.at("p.selling_price span").text.gsub(/(円|,)/, "")
            # p p

            price.ngsj = p
            supplier.ngsj = url
          end
        when 1
          if div = page.at(".cat_list_003")
            detail_url = div.at("tr a").attr("href")
            detail_page = agent.get(detail_url)
            trs = detail_page.search("table.table1 tr")
            text = trs[1].at("td.CELL_2").text

            # text = div.at(".price").text

            /^([0-9,]+)/ =~ text
            p = $1.gsub(",", "")
            p p

            price.iiparts = p
            supplier.iiparts = url
          end
        when 2
          result = self.item_search(keyword)
          p result[:price]
          price.amazon = result[:price]
          supplier.amazon = result[:url]
        when 3
          if div = page.at("#tableSarch")
            if tr = div.search("tr")[1]

              td = tr.search("td")[0]
              detail_url = td.at("a").attr("href")
              detail_page = agent.get(detail_url)

              table = detail_page.at("#rakutenLimitedId_cart")
              trs = table.search("tr")
              tds = trs[1].search("td")
              p = tds[1].at(".price2").text.gsub(/(±ß\n|,)/, "")
              p p

              # td = tr.search("td")[4]
              # # p td

              # p = td.at("font").text.gsub(/( 円|,)/, "")
              # p p

              price.rakuten = p
              supplier.rakuten = url
            end
          end
        when 4
          if li = page.at("ul.ptItem li")
            detail_url = li.at("dl dt a").attr("href")

            detail_page = agent.get(detail_url)
            p = detail_page.at(".elPrice span").text.gsub(/,/, "")
            p p

            # p = li.at("b.elPrice").text.gsub(/(±ß|,)/, "")
            # p p

            price.yahoo = p
            supplier.yahoo = url
          end
        end
      rescue
      end
    end

    array = Array.new
    array << price.ngsj unless price.ngsj.nil?
    array << price.iiparts unless price.iiparts.nil?
    array << price.amazon unless price.amazon.nil?
    array << price.rakuten unless price.rakuten.nil?
    array << price.yahoo unless price.yahoo.nil?
    array.sort
    p array

    low = array.first
    high = array.last
    percentage = Profit.last.try(:percentage) || 0.5

    if !low.nil? && !high.nil?
      price.selling_price = low + (high - low) * percentage
    elsif !low.nil?
      price.selling_price = low * 1.3
    end

    # p price
    # p supplier

    price.save
    supplier.save
    ActiveRecord::Base.connection.update("update spree_prices set amount = #{price.selling_price} where variant_id = #{product.id}")
  end

  def self.refresh_prices(product)
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

  private
  def self.item_search(keyword)
    request = Vacuum.new("JP")
    request.configure(
                      aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG
                      )

    parameters = {
      "SearchIndex" => "Automotive",
      "Keywords" => keyword,
      "ResponseGroup" => "Medium"
    }

    # amazon.com
    begin
      response = request.item_search(query: parameters).to_h
      # puts response
    rescue TimeoutError
      warn "TimeoutError"
    rescue  => ex
      case ex
        # when "404" then
        #   warn "404: #{ex.page.uri} does not exist"
      when "Excon::Errors::ServiceUnavailable: Expected(200) <=> Actual(503 Service Unavailable)" then
        if @retryuri != url && sec = ex.page.header["Retry-After"]
          warn "503: will retry #{ex.page.uri} in #{sec}seconds"
          @retryuri = ex.page.uri
          sleep sec.to_i
          retry
        end
      when /\A5/ then
        warn "#{ex.code}: internal error"
      else
        warn ex.message
      end
    end

    result = Hash.new

    if response && response["ItemSearchResponse"]["Items"]["Item"]
      item = response["ItemSearchResponse"]["Items"]["Item"][0]
      if !item.nil? && item.instance_of?(Hash)
        if item["OfferSummary"] && item["OfferSummary"]["LowestNewPrice"]
          price = (item["OfferSummary"]["LowestNewPrice"]["Amount"])
          result[:price] = price

          Bitly.use_api_version_3
          Bitly.configure do |config|
            config.api_version = 3
            config.access_token = "c7b6ba72ff78178e3e0cc063f4823820ba2dfb01"
          end
          url = Bitly.client.shorten(item["DetailPageURL"]).short_url
          result[:url] = url
        end
      end
    end
    return result
  end
end
