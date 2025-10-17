class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.references :member, null: false, foreign_key: true
      t.string :name
      t.string :phone

      t.timestamps
    end
  end
end
