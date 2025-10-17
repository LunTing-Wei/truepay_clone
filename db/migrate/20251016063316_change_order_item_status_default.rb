class ChangeOrderItemStatusDefault < ActiveRecord::Migration[8.0]
  def change
      change_column_default :order_items, :status, from: nil, to: 0
      change_column_null :order_items, :status, false, 0
  end
end
