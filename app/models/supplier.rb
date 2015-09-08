class Supplier < ActiveRecord::Base
  belongs_to :spree_product

  def self.update_price(spree_product_id)
    product = Spree::Product.find(spree_product_id)
    Price.get_price(product)
  end
end
