class Merchant < ApplicationRecord
  belongs_to :member
  has_many :products, dependent: :destroy

  validates :shop_name,presence:true
  validates :subdomain,presence:true,uniqueness:true
end
