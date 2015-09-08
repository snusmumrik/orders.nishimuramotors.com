class CreatePrices < ActiveRecord::Migration
  def change
    create_table :prices do |t|
      t.references :spree_product, index: true, foreign_key: true
      t.integer :ngsj
      t.integer :iiparts
      t.integer :amazon
      t.integer :rakuten
      t.integer :yahoo

      t.timestamps null: false
    end
  end
end
