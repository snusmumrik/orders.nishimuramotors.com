class CreateProfits < ActiveRecord::Migration
  def change
    create_table :profits do |t|
      t.float :percentage

      t.timestamps null: false
    end
  end
end
