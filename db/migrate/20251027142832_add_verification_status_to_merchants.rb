class AddVerificationStatusToMerchants < ActiveRecord::Migration[8.0]
  def change
    add_column :merchants, :verification_status, :integer, default: 0, null: false
    add_column :merchants, :verified_at, :datetime
    add_column :merchants, :rejection_reason, :text
  end
end
