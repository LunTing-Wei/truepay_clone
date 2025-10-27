class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :customer

  enum :status, { unused: 0, used: 1, expired: 2 }
  
  validates :ticket_code, presence: true, uniqueness: true

  before_validation :generate_ticket_code, on: :create
  def redeem!(merchant)
      return [false, "您無權限驗證此票券"] if product.merchant != merchant
      return [false, "票券已使用"] if used?
      return [false, "票券已過期"] if expired_or_overdue?

      update!(status: :used, used_at: Time.current)
      [true, "票券使用成功"]
  end

  def expired_or_overdue?
      valid_until && Time.current > valid_until
  end

  def qr_code_svg
    require 'rqcode'

    qr = RQRCode::QRCode.new(ticket_code)
    qr.as_svg(
      module_size: 4,
      standalone: true,
      use_path: true
    )
  end

    private

  def generate_ticket_code
      return if ticket_code.present?

      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      random_suffix = SecureRandom.hex(4).upcase
      self.ticket_code = "TKT#{timestamp}#{random_suffix}"
  end
end
