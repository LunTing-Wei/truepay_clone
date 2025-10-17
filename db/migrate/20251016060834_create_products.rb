class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price,null: false, default: 0
      t.integer :stock,null: false, default: 0
      t.text :description
      t.datetime :ticket_expiry
      t.boolean :is_active,default: true, null: false

      t.timestamps
    end
    add_index :products, :is_active
  end
end
