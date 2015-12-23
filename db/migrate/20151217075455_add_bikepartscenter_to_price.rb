class AddBikepartscenterToPrice < ActiveRecord::Migration
  def change
    add_column :prices, :bikepartscenter, :integer, after: :ngsj
  end
end
