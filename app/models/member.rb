class Member < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  enum :member_type, { customer: 0, merchant: 1 },default: :customer
  has_one :merchant, dependent: :destroy
  has_one :customer, dependent: :destroy

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "格式不正確" },
                    uniqueness: { scope: :member_type, message: "此 Email 已被註冊為此角色" }

  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?

  after_create :create_role_record
  def self.find_for_authentication(warden_conditions)
    where(email: warden_conditions[:email], member_type: warden_conditions[:member_type]).first
  end
  private
  def create_role_record
    if merchant?
      create_merchant!(
        shop_name: "#{email.split('@').first} 的商店",
        subdomain: "shop#{id}"
      )
    else
      create_customer!(
        name: email.split('@').first,
        phone: ""
      )
    end
  end
  def password_required?
      !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
