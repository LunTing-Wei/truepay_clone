class StoresController < ApplicationController
  def show
    @merchant = Merchant.find(params[:id])
    @products = @merchant.products.where(is_active: true, is_deleted: false).order(created_at: :desc)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "找不到此商店"
  end
end
