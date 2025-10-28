class AddBusinessInfoToMerchants < ActiveRecord::Migration[8.0]
  def change
    add_column :merchants, :unified_number, :string
    add_column :merchants, :owner_name, :string
    add_column :merchants, :owner_id_last_four, :string
    add_column :merchants, :business_address, :string
    add_column :merchants, :phone, :string
    add_column :merchants, :customer_service_email, :string
    add_column :merchants, :bank_account, :string

    add_index :merchants, :unified_number, unique: true, where: "unified_number IS NOT NULL"
  end
end
