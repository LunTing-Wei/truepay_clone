class CreateMerchants < ActiveRecord::Migration[8.0]
  def change
    create_table :merchants do |t|
      t.references :member, null: false, foreign_key: true
      t.string :shop_name
      t.string :subdomain

      t.timestamps
    end
    add_index :merchants, :subdomain, unique:true
  end
end
