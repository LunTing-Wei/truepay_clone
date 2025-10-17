class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :unit_price
      t.integer :amount
      t.integer :status
      t.integer :provider
      t.datetime :paid_at

      t.timestamps
    end
    add_index :orders, :status
    add_index :orders, [:customer_id, :created_at]
  end
end
