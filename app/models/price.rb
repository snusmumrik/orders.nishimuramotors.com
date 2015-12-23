# -*- coding: utf-8 -*-
require "mechanize"

class Price < ActiveRecord::Base
  belongs_to :spree_product

  def self.get_prices
    Spree::Product.find_each do |p|
      Price.get_price(p)
    end
  end

  def self.get_price(product)
    taxon_id = ActiveRecord::Base.connection.select_one("select * from spree_products_taxons where product_id  = #{product.id}")["taxon_id"] rescue nil
    name = product.name
    puts "NAME: #{name}"

    keyword = name.sub(/(専用|保証付き|１年間保証付き|【液入充電済】|【液付属】|一本|1本)/, "").strip
    puts "KEYWORD: #{keyword}"

    search_urls = ["http://nbsj.ocnk.net/product-list?keyword=#{keyword}&order=asc",
                   "http://11parts.shop-pro.jp/?mode=srh&cid=&keyword=#{keyword}&sort=p",
                   "http://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=カタカナ&url=node%3D2045198051&field-keywords=#{keyword}",
                   "http://search.rakuten.co.jp/search/inshop-mall?f=1&v=2&sid=229933&uwd=1&s=1&p=1&sitem=#{keyword}",
                   "http://store.shopping.yahoo.co.jp/bike-parts-center/search.html?p=#{keyword}&X=2",
                   # "http://search.shopping.yahoo.co.jp/search?ei=UTF-8&p=#{keyword}&va=&ve=&tab_ex=commerce&oq=&cid=&pf=&pt=&used=0&seller=0&X=2",
                   "http://www.bike-partscenter.com/product-list?keyword=#{URI.decode(keyword)}&order=asc",
                   "http://nbs-tire.ocnk.net/product-list?keyword=#{URI.decode(keyword)}&order=asc"]


    if supplier = Supplier.where(["spree_product_id = ?", product.id]).first
      search_urls[0] = supplier.ngsj unless supplier.ngsj.blank?
      search_urls[1] = supplier.iiparts unless supplier.iiparts.blank?
      search_urls[2] = supplier.amazon unless supplier.amazon.blank?
      search_urls[3] = supplier.rakuten unless supplier.rakuten.blank?
      search_urls[4] = supplier.yahoo unless supplier.yahoo.blank?
      search_urls[5] = supplier.bikepartscenter unless supplier.bikepartscenter.blank?
      search_urls[6] = supplier.nbstire unless supplier.nbstire.blank?
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
      puts "#{i}: #{url}"

      begin
        page = agent.get(url) unless i == 2

        case i
        when 0
          if taxon_id && taxon_id >= 241
            puts "SKIP"
            next
          end

          if li = page.at("ul.layout160 li")
            detail_url = page.at("div.item_data a").attr("href")
            detail_page = agent.get(detail_url)
            p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
            puts "PRICE: #{p}"

            # p = li.at("p.selling_price span").text.gsub(/(円|,)/, "")
            # puts "PRICE: #{p}"

            price.ngsj = p
            supplier.ngsj = detail_url
          elsif page.at("#pricech")
            p = page.at("#pricech").text.gsub(/(円|,)/, "")
            puts "PRICE: #{p}"

            price.ngsj = p
            supplier.ngsj = url
          else
            puts "ITEM NOT FOUND"
            price.ngsj = nil
            supplier.ngsj = nil
          end
        when 1
          if taxon_id && taxon_id >= 241
            puts "SKIP"
            next
          end

          if div = page.at(".cat_list_003")
            detail_url = div.at("tr a").attr("href")
            detail_page = agent.get(detail_url)
            trs = detail_page.search("table.table1 tr")
            text = trs[1].at("td.CELL_2").text

            # text = div.at(".price").text

            /^([0-9,]+)/ =~ text
            p = $1.gsub(",", "")
            puts "PRICE: #{p}"

            price.iiparts = p
            host = "http://11parts.shop-pro.jp/"
            supplier.iiparts = host + detail_url
          elsif page.search("table.table1 tr")
            trs = page.search("table.table1 tr")
            text = trs[1].at("td.CELL_2").text

            /^([0-9,]+)/ =~ text
            p = $1.gsub(",", "")
            puts "PRICE: #{p}"

            price.iiparts = p
            supplier.iiparts = url
          else
            puts "ITEM NOT FOUND"
            price.iiparts = nil
            supplier.iiparts = nil
          end
        when 2
          if result = self.item_search(keyword)
            if result[:price]
              puts "PRICE: #{result[:price]}"
              price.amazon = result[:price]
              supplier.amazon = result[:url]
            end
          else
            puts "ITEM NOT FOUND"
            price.amazon = nil
            supplier.amazon = nil
          end

          # # get retail amazon price not from third party vendors
          # begin
          #   if amazon_retail_price = page.search("span[id='priceblock_ourprice']").text.sub!("$", "").to_f
          #     p "Amazon Retail Price: #{amazon_price}"
          #     price.amazon = amazon_retail_price
          #   end
          # rescue => ex
          #   warn ex.message
          # end
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
              puts "PRICE: #{p}"

              # td = tr.search("td")[4]
              # # puts td

              # p = td.at("font").text.gsub(/( 円|,)/, "")
              # puts "PRICE: #{p}"

              price.rakuten = p
              supplier.rakuten = Supplier.shorten_url(Supplier.get_rakuten_link(detail_url))
            end
          elsif page.at("#rakutenLimitedId_cart")
            table = page.at("#rakutenLimitedId_cart")
            trs = table.search("tr")
            tds = trs[1].search("td")
            p = tds[1].at(".price2").text.gsub(/(±ß\n|,)/, "")
            puts "PRICE: #{p}"

            price.rakuten = p
            supplier.rakuten = url
          else
            puts "ITEM NOT FOUND"
            price.rakuten = nil
            supplier.rakuten = nil
          end
        when 4
          # for bike-parts-center
          if li = page.at("ul.ptItem li")
            detail_url = li.at("dl dt a").attr("href")

            detail_page = agent.get(detail_url)
            p = detail_page.at(".elPrice span").text.gsub(/,/, "")
            puts "PRICE: #{p}"

            # p = li.at("b.elPrice").text.gsub(/(±ß|,)/, "")
            # puts "PRICE: #{p}"

            price.yahoo = p
            supplier.yahoo = detail_url
          # if h3 = page.at("h3.elName")
          #   detail_url = h3.at("a").attr("href")

          #   detail_page = agent.get(detail_url)
          #   p = detail_page.at(".elPrice span").text.gsub(/,/, "")
          #   puts "PRICE: #{p} by SEARCH"

          #   # p = li.at("b.elPrice").text.gsub(/(±ß|,)/, "")
          #   # puts "PRICE: #{p}"

          #   price.yahoo = p
          #   supplier.yahoo = detail_url
          elsif page.at("span.elNum")
            p = page.at("span.elNum").text.gsub(/,/, "")
            puts "PRICE: #{p} by DETAIIL"

            price.yahoo = p
            supplier.yahoo = url
          else
            puts "ITEM NOT FOUND"
            price.yahoo = nil
            supplier.yahoo = nil
          end
        when 5
          if taxon_id && taxon_id < 241
            puts "SKIP"
            next
          end

          if a = page.at("div.list_table_middle h2 a")
            detail_url = a.attr("href")
            detail_page = agent.get(detail_url)
            p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
            puts "PRICE: #{p}"

            price.bikepartscenter = p
            supplier.bikepartscenter = detail_url
          elsif page.at("#pricech")
            p = page.at("#pricech").text.gsub(/(円|,)/, "")
            puts "PRICE: #{p}"

            price.bikepartscenter =  p
            supplier.bikepartscenter = url
          else
            puts "ITEM NOT FOUND"
            price.bikepartscenter = nil
            supplier.bikepartscenter = nil
          end
        when 6
          if taxon_id && taxon_id < 241
            puts "SKIP"
            next
          end

          self.sign_in_to_nbstire(agent)

          if a = page.at("div.list_table_middle h2 a")
            detail_url = a.attr("href")
            detail_page = agent.get(detail_url)
            p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
            if p =~ /[0-9,]/
              puts "PRICE: #{p}"

              price.nbstire = p
              supplier.nbstire = detail_url
            else
              puts "ITEM NOT FOUND"
              price.nbstire = nil
              supplier.nbstire = nil
            end
          elsif page.at("#pricech")
            p = page.at("#pricech").text.gsub(/(円|,)/, "")
            if p =~ /[0-9,]/
              puts "PRICE: #{p}"

              price.nbstire =  p
              supplier.nbstire = url
            else
              puts "ITEM NOT FOUND"
              price.nbstire = nil
              supplier.nbstire = nil
            end
          end
        end
      rescue => ex
        puts ex.message
      end
    end

    # puts price
    # puts supplier

    price.save
    supplier.save
    self.refresh_price(product)
  end

  def self.refresh_prices
    Spree::Product.all.each do |p|
      Price.refresh_price(p)
    end
  end

  def self.refresh_price(product)
    price = Price.where(["spree_product_id = ?", product.id]).first
    array = Array.new
    array << price.ngsj unless price.ngsj.nil?
    array << price.iiparts unless price.iiparts.nil?
    array << price.amazon unless price.amazon.nil?
    array << price.rakuten unless price.rakuten.nil?
    array << price.yahoo unless price.yahoo.nil?
    array << price.bikepartscenter unless price.bikepartscenter.nil?
    array << price.nbstire unless price.nbstire.nil?
    array.sort!
    puts array

    low = array.first
    high = array.last
    percentage = Profit.last.try(:percentage) || 0.5

    if !low.nil? && !high.nil?
      new_price = (low + (high - low) * percentage).round(-1)
      lowest_price = low
    elsif !low.nil?
      new_price = (low * (1 + percentage)).round(-1)
      lowest_price = low
    end

    new_price = lowest_price + 500 if lowest_price

    puts new_price
    price.update_attributes({selling_price: new_price, lowest_price: lowest_price })

    begin
      product.avilable_on = nil if array.size == 0
    rescue => ex
      puts ex.message
    end

    ActiveRecord::Base.connection.update("update spree_prices set amount = #{new_price} where variant_id = #{product.id}") if new_price
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
      if response["ItemSearchResponse"]["Items"]["Item"].instance_of?(Array)
        item = response["ItemSearchResponse"]["Items"]["Item"][0]
      else
        item = response["ItemSearchResponse"]["Items"]["Item"]
      end
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

  def self.search_amazon_iamges(product, item)
    if item["ImageSets"] && item["ImageSets"]["ImageSet"].instance_of?(Array)
      for j in 0..4
        if !item["ImageSets"]["ImageSet"][j].blank?
          image_url = item["ImageSets"]["ImageSet"][j]["LargeImage"]["URL"]
          self.save_image(product, image_url)
        end
      end
    elsif item["ImageSets"] && item["ImageSets"]["ImageSet"]
      image_url = item["ImageSets"]["ImageSet"]["LargeImage"]["URL"]
      self.save_image(product, image_url)
    end
  end

  def self.save_image(product, item)
    p image_url
    begin
      product.images.create(attachment: open(image_url))
    rescue => ex
      p ex.message
    end
  end

  def self.sign_in_to_nbstire(agent)
    login_page = agent.get("http://nbs-tire.ocnk.net")
    form = login_page.form_with(action: "https://nbs-tire.ocnk.net/login-auth")
    form.field_with(name: "email").value = NBS_EMAIL
    form.field_with(name: "password").value = NBS_PASSWORD
    button = form.button_with(id: "side_login_submit")
    login_page2 = agent.submit(form, button)
    # if login_page2.at("input[value='ログアウト']")
    #   puts "SIGNED IN"
    #   return true
    # else
    #   puts "SIGN IN FAILED"
    #   return false
    # end
  end
end
