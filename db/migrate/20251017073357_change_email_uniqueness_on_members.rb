class ChangeEmailUniquenessOnMembers < ActiveRecord::Migration[8.0]
  def change
    remove_index :members, :email if index_exists?(:members, :email)

    add_index :members, [:email, :member_type], unique: true
  end
end
