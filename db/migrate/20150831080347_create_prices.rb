class CreatePrices < ActiveRecord::Migration
  def change
    create_table :prices do |t|
      t.references :spree_product, index: true, foreign_key: true
      t.string :ngsj
      t.string :iiparts
      t.string :amazon
      t.string :rakuten
      t.string :yahoo

      t.timestamps null: false
    end
  end
end
