class Merchant < ApplicationRecord
  belongs_to :member
  has_many :products, dependent: :destroy
  enum :verification_status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    suspended: 3
  }, default: :pending

  # ========== 基本驗證 ==========
  validates :shop_name, presence: true
  validates :subdomain, presence: true, uniqueness: true

  # ========== 審核所需欄位驗證（只在新建立或更新時檢查）==========
  validates :unified_number,
    format: {
      with: /\A\d{8}\z/,
      message: "必須是8位數字"
    },
    uniqueness: { case_sensitive: false },
    allow_blank: true

  validates :owner_name,
    length: { minimum: 2, maximum: 30 },
    allow_blank: true

  validates :owner_id_last_four,
    format: {
      with: /\A[A-Z0-9]{4}\z/i,
      message: "必須是4位數字或字母"
    },
    allow_blank: true

  validates :business_address,
    length: { minimum: 5, maximum: 100 },
    allow_blank: true

  validates :phone,
    format: {
      with: /\A(09\d{8}|0\d{1,2}-?\d{6,8})\z/,
      message: "格式不正確（範例：0912345678 或 02-12345678）"
    },
    allow_blank: true

  validates :customer_service_email,
    format: {
      with: URI::MailTo::EMAIL_REGEXP,
      message: "格式不正確"
    },
    allow_blank: true

  validates :bank_account,
    format: {
      with: /\A\d{10,16}\z/,
      message: "必須是10-16位數字"
    },
    allow_blank: true

  # ========== 自動審核邏輯 ==========
  def auto_approvable?
    unified_number.present? &&
    owner_name.present? &&
    owner_id_last_four.present? &&
    business_address.present? &&
    phone.present? &&
    customer_service_email.present?
  end

  def auto_approve!
    if auto_approvable?
      update!(
        verification_status: :approved,
        verified_at: Time.current,
        rejection_reason: nil
      )
      true
    else
      false
    end
  end
end
