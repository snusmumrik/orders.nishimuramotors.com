class AddSellingPriceToPrice < ActiveRecord::Migration
  def change
    add_column :prices, :selling_price, :integer, after: :spree_product_id
  end
end
