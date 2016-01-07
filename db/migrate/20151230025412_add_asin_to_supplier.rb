class AddAsinToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :asin, :string, after: :amazon
  end
end
