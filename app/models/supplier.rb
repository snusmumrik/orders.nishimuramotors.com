class Supplier < ActiveRecord::Base
  belongs_to :spree_product

  def self.get_rakuten_link(url)
    affiliate_link = "http://hb.afl.rakuten.co.jp/hgc/04ca51e6.8117788a.10c41bdd.777df5cb/?pc=#{url}%3fscid%3daf_link_urltxt&amp;m=http%3a%2f%2fm.rakuten.co.jp"
    # Supplier.shorten_url(affiliate_link)
  end

  def self.shorten_url(url)
    Bitly.use_api_version_3
    Bitly.configure do |config|
      config.api_version = 3
      config.access_token = "c7b6ba72ff78178e3e0cc063f4823820ba2dfb01"
    end
    shorten_url = Bitly.client.shorten(url).short_url
  end
end
