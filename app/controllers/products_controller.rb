class ProductsController < ApplicationController
  before_action :authenticate_member!
  before_action :ensure_merchant!
  before_action :ensure_merchant_approved!, only: [ :new, :create, :edit, :update ]
  before_action :set_product, only: [ :edit, :update, :destroy ]
  def index
    @products = current_member.merchant.products
                              .order(created_at: :desc)
  end

  def new
    @product = Product.new
  end

  def create
    @product = current_member.merchant.products.build(product_params)
    if @product.save
      redirect_to products_path, notice: "商品建立成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to products_path, notice: "商品更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.orders.exists?
      @product.update!(is_active: false)
      redirect_to products_path, notice: "商品已下架（因為有訂單記錄，無法完全刪除)"
    else
      @product.destroy!
      redirect_to products_path, notice: "商品刪除成功"
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to products_path, alert: "無法刪除：此商品有關聯記錄"
  end

  private

  def ensure_merchant!
    unless current_member.merchant?
      redirect_to tickets_path, alert: "此頁面僅限商家訪問"
    end
  end

  def ensure_merchant_approved!
    unless current_member.merchant.approved?
      redirect_to products_path, alert: "您的商家帳號尚未通過審核，無法進行此操作"
    end
  end

  def set_product
    @product = current_member.merchant.products.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "找不到此商品或無權訪問"
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :stock, :ticket_expiry)
  end
end
