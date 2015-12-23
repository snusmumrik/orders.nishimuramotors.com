class AddNbstireToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :nbstire, :string, after: :iiparts
  end
end
