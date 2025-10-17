class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :ticket_code
      t.integer :status
      t.datetime :valid_until
      t.datetime :used_at

      t.timestamps
    end
    add_index :order_items, :ticket_code, unique: true
    add_index :order_items, :status
    add_index :order_items, [:customer_id, :status]
  end
end
