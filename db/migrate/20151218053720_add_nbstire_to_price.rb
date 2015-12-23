class AddNbstireToPrice < ActiveRecord::Migration
  def change
    add_column :prices, :nbstire, :integer, after: :iiparts
  end
end
