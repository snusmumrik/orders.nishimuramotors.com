class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :supplier
      t.string :identifier
      t.string :password

      t.timestamps null: false
    end
  end
end
