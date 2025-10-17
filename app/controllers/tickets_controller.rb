class TicketsController < ApplicationController
  before_action :authenticate_member!
  before_action :ensure_customer!
  def index
    @tickets = current_member.customer.order_items
                             .includes(:product, :order)
                             .order(created_at: :desc)
  end
  private
  def ensure_customer!
    unless current_member.customer?
      redirect_to products_path, alert: '此頁面僅限消費者訪問'
    end
  end
end
