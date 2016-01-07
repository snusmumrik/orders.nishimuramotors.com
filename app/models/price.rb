# -*- coding: utf-8 -*-
require "mechanize"

class Price < ActiveRecord::Base
  belongs_to :spree_product

  def self.get_prices
    Spree::Product.find_each do |p|
      Price.get_price(p)
    end
  end

  def self.get_price(product, force_flg = false)
    taxon_id = ActiveRecord::Base.connection.select_one("select * from spree_products_taxons where product_id  = #{product.id}")["taxon_id"] rescue nil
    name = product.name
    puts "NAME: #{name}"

    keyword = name.gsub(/(◆|★|電解|液付属付属|液付属|高品質|専用|保証付き|保証書付|１年間保証付き|1年保証付|タイプ|激安|防災・防犯システム等多目的バッテリー|ハーレー用|一本|1本|[^\s　]+互換|ジェルバッテリー|バイクバッテリー|バイク用タイヤ|【[^】]+】|（[^）]+）)|＜|＞/, "").gsub("　", " ").sub("GSユアサバッテリー", "GSユアサ バッテリー").strip
    puts "KEYWORD: #{keyword}"

    if supplier = Supplier.where(["spree_product_id = ?", product.id]).first
      if force_flg == false
        search_urls = [supplier.ngsj, supplier.iiparts, supplier.amazon, supplier.rakuten, supplier.yahoo, supplier.bikepartscenter, supplier.nbstire]

        # search_urls[1] = "http://11parts.shop-pro.jp" if search_urls[1].blank?
        # search_urls[3] = "http://search.rakuten.co.jp/search/inshop-mall?f=1&v=2&sid=229933&uwd=1&s=1&p=1&sitem=#{keyword}&st=O&nitem=&min=&max=" if search_urls[3].blank?
        # search_urls[4] = "http://store.shopping.yahoo.co.jp/bike-parts-center/search.html?p=#{keyword}&X=2" if search_urls[4].blank?
        # search_urls[6] = "http://nbs-tire.ocnk.net/product-list?keyword=#{URI.decode(keyword)}&order=asc" if search_urls[6].blank?
      else
        search_urls = ["http://nbsj.ocnk.net/product-list?keyword=#{keyword}&order=asc",
                       # "http://11parts.shop-pro.jp/?mode=srh&cid=&keyword=#{keyword.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z').gsub(/[^0-9a-zA-Z_=\s-]?/, '')}&sort=p",
                       "http://11parts.shop-pro.jp",
                       "http://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=カタカナ&url=node%3D2045198051&field-keywords=#{keyword}",
                       "http://search.rakuten.co.jp/search/inshop-mall?f=1&v=2&sid=229933&uwd=1&s=1&p=1&sitem=#{keyword}&st=O&nitem=&min=&max=",
                       "http://store.shopping.yahoo.co.jp/bike-parts-center/search.html?p=#{keyword}&X=2",
                       "http://www.bike-partscenter.com/product-list?keyword=#{URI.decode(keyword)}&order=asc",
                       "http://nbs-tire.ocnk.net/product-list?keyword=#{URI.decode(keyword)}&order=asc"]
      end
    else
      supplier = Supplier.new
      supplier.spree_product_id = product.id

      search_urls = ["http://nbsj.ocnk.net/product-list?keyword=#{keyword}&order=asc",
                     "http://11parts.shop-pro.jp/?mode=srh&cid=&keyword=#{keyword.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z').gsub(/[^0-9a-zA-Z_=\s-]?/, '')}&sort=p",
                     "http://www.amazon.co.jp/s/ref=nb_sb_noss?__mk_ja_JP=カタカナ&url=node%3D2045198051&field-keywords=#{keyword}",
                     "http://search.rakuten.co.jp/search/inshop-mall?f=1&v=2&sid=229933&uwd=1&s=1&p=1&sitem=#{keyword}&st=O&nitem=&min=&max=",
                     "http://store.shopping.yahoo.co.jp/bike-parts-center/search.html?p=#{keyword}&X=2",
                     "http://www.bike-partscenter.com/product-list?keyword=#{URI.decode(keyword)}&order=asc",
                     "http://nbs-tire.ocnk.net/product-list?keyword=#{URI.decode(keyword)}&order=asc"]
    end

    # puts "SEARCH URLS: #{search_urls}"

    unless price = Price.where(["spree_product_id = ?", product.id]).first
      price = Price.new
      price.spree_product_id = product.id
    end

    agent = Mechanize.new
    search_urls.each_with_index do |url, i|
      puts "#{i}: #{url}"

      begin
        case i
        when 0
          if url.blank?
            price.ngsj = nil
            supplier.ngsj = nil
          else
            page = agent.get(url)
            if taxon_id && taxon_id >= 241
              puts "SKIP"
              price.ngsj = nil
              supplier.ngsj = nil
            elsif page.at("#pricech")
              p = page.at("#pricech").text.gsub(/(円|,)/, "")
              puts "PRICE: #{p} BY DETAIL"

              price.ngsj = p
              supplier.ngsj = url
            elsif li = page.at("ul.layout160 li")
              detail_url = page.at("div.item_data a").attr("href")
              detail_page = agent.get(detail_url)
              p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
              puts "PRICE: #{p} BY SEARCH"

              # p = li.at("p.selling_price span").text.gsub(/(円|,)/, "")
              # puts "PRICE: #{p}"

              price.ngsj = p
              supplier.ngsj = detail_url
            else
              puts "ITEM NOT FOUND"
              price.ngsj = nil
              supplier.ngsj = nil
            end
          end
        when 1
          if url.blank?
            price.iiparts = nil
            supplier.iiparts = nil
          else
            page = agent.get(url)
            if taxon_id && taxon_id >= 241
              puts "SKIP"
              price.iiparts = nil
              supplier.iiparts = nil
              next
            end

            if url == "http://11parts.shop-pro.jp"
              search_result = agent.get(url)
              search_result.encoding = "euc-jp"
              form = search_result.form_with(action: "http://11parts.shop-pro.jp/")
              form.field_with(name: "keyword").value = keyword.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z')
              button = form.button_with(value: "商品検索")
              page = agent.submit(form, button)
              puts keyword
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
            elsif page.at("table.table1")
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
          end
        when 2
          if supplier.amazon.blank?
            puts "ITEM NOT FOUND"
            price.amazon = nil
            supplier.amazon = nil
          elsif !supplier.asin.blank?
            puts "SEARCY BY ASIN"
            if result = self.item_lookup(supplier.asin)
              if result[:price]
                puts "PRICE: #{result[:price]}"
                price.amazon = result[:price]
                supplier.amazon = result[:url]
                supplier.asin = result[:asin]
              end
            else
              puts "ITEM NOT FOUND"
              price.amazon = nil
              supplier.amazon = nil
            end
          elsif result = self.item_search(keyword)
            puts "SEARCY BY KEYWORD"
            if result[:price]
              puts "PRICE: #{result[:price]}"
              price.amazon = result[:price]
              supplier.amazon = result[:url]
              supplier.asin = result[:asin]
            else
              puts "ITEM NOT FOUND"
              price.amazon = nil
              supplier.amazon = nil
            end
          end

          # # get retail amazon price not from third party vendors
          # begin
          #   if amazon_retail_price = page.search("span[id='priceblock_ourprice']").text.gsub(/(￥ |,)/, "")
          #     p "Amazon Retail Price: #{amazon_retail_price}"
          #     price.amazon = amazon_retail_price
          #   end
          # rescue => ex
          #   warn ex.message
          #   price.amazon = nil
          # end
        when 3
          if url.blank?
            price.rakuten = nil
            supplier.rakuten = nil
          else
            page = agent.get(url)
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
          end
        when 4
          if url.blank?
            price.yahoo = nil
            supplier.yahoo = nil
          else
            page = agent.get(url)
            # for bike-parts-center
            if li = page.at("ul.ptItem li")
              detail_url = li.at("dl dt a").attr("href")
              puts "DETAIL URL: #{detail_url}"

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
          end
        when 5
          if url.blank?
            price.bikepartscenter = nil
            supplier.bikepartscenter = nil
          else
            page = agent.get(url)
            if taxon_id && taxon_id < 241
              puts "SKIP"
              price.bikepartscenter = nil
              supplier.bikepartscenter = nil
            elsif a = page.at("div.list_table_middle h2 a")
              detail_url = a.attr("href")
              detail_page = agent.get(detail_url)
              p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
              puts "PRICE: #{p} BY SEARCH"

              price.bikepartscenter = p
              supplier.bikepartscenter = detail_url
            elsif page.at("#pricech")
              p = page.at("#pricech").text.gsub(/(円|,)/, "")
              puts "PRICE: #{p} BY DETAIL"

              price.bikepartscenter =  p
              supplier.bikepartscenter = url
            else
              puts "ITEM NOT FOUND"
              price.bikepartscenter = nil
              supplier.bikepartscenter = nil
            end
          end
        when 6
          if url.blank?
            price.nbstire = nil
            supplier.nbstire = nil
          else
            self.sign_in_to_nbstire(agent)
            page = agent.get(url)            

            if taxon_id && taxon_id < 241
              puts "SKIP"
              price.nbstire = nil
              supplier.nbstire = nil
              next
            end

            if a = page.at("div.list_table_middle h2 a")
              detail_url = a.attr("href")
              detail_page = agent.get(detail_url)
              p = detail_page.at("#pricech").text.gsub(/(円|,)/, "")
              if p =~ /[0-9,]/
                puts "PRICE: #{p}"

                price.nbstire = p
                supplier.nbstire = detail_url
              else
                puts "ITEM NOT FOUND1"
                price.nbstire = nil
                supplier.nbstire = nil
              end
            elsif page.at("#pricech")
              p = page.at("#pricech").text.gsub(/(円|,)/, "")
              puts p
              if p =~ /[0-9,]/
                puts "PRICE: #{p}"

                price.nbstire =  p
                supplier.nbstire = url
              else
                puts "ITEM NOT FOUND2"
                price.nbstire = nil
                supplier.nbstire = nil
              end
            else
              puts "ITEM NOT FOUND3"
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
      puts response
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
        result[:asin] = item["ASIN"]
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

  def self.item_lookup(item_id)
    request = Vacuum.new("JP")
    request.configure(
                      aws_access_key_id: AWS_ACCESS_KEY_ID,
                      aws_secret_access_key: AWS_SECRET_ACCESS_KEY,
                      associate_tag: ASSOCIATE_TAG
                      )

    parameters = {
      "ItemId" => item_id,
      "ResponseGroup" => "Medium, OfferSummary"
    }

    # amazon.com
    begin
      response = request.item_lookup(query: parameters).to_h
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

    if response && response["ItemLookupResponse"]["Items"]["Item"]
      if response["ItemLookupResponse"]["Items"]["Item"].instance_of?(Array)
        item = response["ItemLookupResponse"]["Items"]["Item"][0]
      else
        item = response["ItemLookupResponse"]["Items"]["Item"]
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

          result[:asin] = item["ASIN"]
        end
      end
    end
    return result
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
