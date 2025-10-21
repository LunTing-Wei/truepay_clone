class AddTransactionIdToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :transaction_id, :string
    add_index :orders, :transaction_id, unique:true
  end
end
