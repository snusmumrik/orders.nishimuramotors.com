class AddBikepartscenterToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :bikepartscenter, :string, after: :ngsj
  end
end
