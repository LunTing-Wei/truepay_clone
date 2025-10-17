class Order < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  has_many :items, class_name: 'OrderItem', dependent: :destroy

  enum :status, { pending: 0, paid: 1, failed: 2, cancelled: 3 }
  enum :provider, { newebpay: 0, linepay: 1 }

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount, presence: true

  before_validation :calculate_amount

  after_update :generate_tickets, if: :saved_change_to_status_to_paid?

  private
  def calculate_amount
    self.amount = (unit_price * quantity).to_i if unit_price && quantity
  end
  def generate_tickets
      # 防止重複生成
      return if items.any?

      # 用 transaction 確保原子性
      transaction do
        quantity.times do |i|
          items.create!(
            product: product,
            customer: customer,
            valid_until: calculate_ticket_expiry
          )
        end
      end
  end

  def calculate_ticket_expiry
      # 如果商品有設定過期時間，用商品的；否則預設 180 天
      product.ticket_expiry || 180.days.from_now
  end

    # 檢查是否剛剛變更為 paid 狀態
  def saved_change_to_status_to_paid?
      saved_change_to_status? && paid?
  end
end
