class TicketsController < ApplicationController
  before_action :authenticate_member!
  before_action :ensure_customer!, only: [:index]
  before_action :ensure_merchant!, only: [:scan, :verify]
  def index
    @tickets = current_member.customer.order_items
                             .includes(:product, :order)
                             .order(created_at: :desc)
  end

  def scan
    
  end
  def verify
    ticket = OrderItem.find_by(ticket_code: params[:ticket_code])
    
    if ticket.nil?
      return render json: { success: false, error: '票券不存在' }, status: :not_found
    end
    
    if ticket.product.merchant.member != current_member
      return render json: { success: false, error: '無權核銷此票券' }, status: :forbidden
    end
    
    if ticket.expired?
      return render json: { success: false, error: '票券已過期' }, status: :unprocessable_entity
    end
    
    if ticket.used?
      return render json: { success: false, error: '票券已使用' }, status: :unprocessable_entity
    end

    ticket.update!(status: :used, used_at: Time.current)
    render json: {
      success: true,
      message: '核銷成功',
      ticket: {
        code: ticket.ticket_code,
        product: ticket.product.name,
        used_at: ticket.used_at
      }
    }
  end
  private
  def ensure_customer!
    unless current_member.customer?
      redirect_to products_path, alert: '此頁面僅限消費者訪問'
    end
  end

  def ensure_merchant!
    unless current_member.merchant?
      redirect_to root_path, alert: '此頁面僅限商家訪問'
    end
  end
end
