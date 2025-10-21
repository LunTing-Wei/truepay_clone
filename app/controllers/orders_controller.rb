class OrdersController < ApplicationController
  before_action :authenticate_member!
  before_action :set_order, only: [:show, :pay, :linepay_request, :linepay_confirm]
  before_action :authorize_order, only: [:show, :pay, :linepay_request, :linepay_confirm]

  def new
    @product = Product.find(params[:product_id])
    @order = Order.new(
      product: @product,
      quantity: 1
    )
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '找不到此商品'
  end

  def create
    product = Product.find(params[:order][:product_id])
    customer = current_member.customer
    @order = Order.new(
      customer: customer,
      product: product,
      quantity: params[:order][:quantity].to_i,
      unit_price: product.price,
      status: :pending
    )
    if @order.save
      redirect_to order_path(@order), notice: '訂單建立成功，請前往付款'
    else
      @product = product
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '找不到此商品'
  end

  def show
    # @order 和授權檢查由 before_action 處理
  end

  def pay
    unless @order.pending?
      redirect_to order_path(@order), alert: '此訂單無法付款'
      return
    end

    if @order.update(status: :paid)
      redirect_to tickets_path, notice: '付款成功！票券已生成，請查看您的票券'
    else
      redirect_to order_path(@order), alert: '付款失敗，請稍後再試'
    end
  end

  def linepay_request
    service = LinePayService.new
    result = service.request_payment(@order)

    if result[:success]
      @order.update(
        transaction_id: result[:transaction_id],
        provider: :linepay
      )
      redirect_to result[:payment_url], allow_other_host: true
    else
      redirect_to order_path(@order), alert: "LINE Pay 請求失敗：#{result[:error_message]}"
    end
  end

  def linepay_confirm
    if @order.paid?
      redirect_to tickets_path, notice: '此訂單已付款完成'
      return
    end

    transaction_id = params[:transactionId]
    unless transaction_id == @order.transaction_id.to_s
      redirect_to order_path(@order), alert: '交易編號不符，請重新付款'
      return
    end

    service = LinePayService.new
    if service.confirm_payment(transaction_id, @order.amount)
      @order.update!(status: :paid, paid_at: Time.current)
      redirect_to tickets_path, notice: '付款成功！票券已生成，請查看您的票券'
    else
      @order.update(status: :failed)
      redirect_to order_path(@order), alert: 'LINE Pay 確認失敗，請聯絡客服'
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '找不到此訂單'
  end

  def authorize_order
    unless @order.customer == current_member.customer
      redirect_to root_path, alert: '無權操作此訂單'
    end
  end
end
