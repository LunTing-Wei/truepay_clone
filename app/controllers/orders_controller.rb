class OrdersController < ApplicationController
  before_action :authenticate_member!
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
    @order = Order.find(params[:id])

    unless @order.customer == current_member.customer
      redirect_to root_path, alert: '無權查看此訂單'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '找不到此訂單'
  end

  def pay
    @order = Order.find(params[:id])
    unless @order.customer == current_member.customer
      redirect_to root_path, alert: '無權操作此訂單'
      return
    end
    unless @order.pending?
      redirect_to order_path(@order), alert: '此訂單無法付款'
      return
    end
    if @order.update(status: :paid)
      redirect_to tickets_path, notice: '付款成功！票券已生成，請查看您的票券'
    else
      redirect_to order_path(@order), alert: '付款失敗，請稍後再試'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '找不到此訂單'
  end
end
