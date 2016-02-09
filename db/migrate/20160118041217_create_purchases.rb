class CreatePurchases < ActiveRecord::Migration
  def change
    create_table :purchases do |t|
      t.references :spree_product, index: true, foreign_key: true
      t.references :spree_order, index: true, foreign_key: true
      t.integer :amount

      t.timestamps null: false
    end
  end
end
