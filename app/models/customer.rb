class Customer < ApplicationRecord
  belongs_to :member
  has_many :orders, dependent: :destroy
  has_many :order_items, dependent: :destroy

  validates:name,presence:true
end
