class AddLowestPriceToPrice < ActiveRecord::Migration
  def change
    add_column :prices, :lowest_price, :integer, after: :selling_price
  end
end
