require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @approved_merchant_member = members(:merchant_one)
    @approved_merchant = merchants(:one)

    @pending_merchant_member = members(:pending_merchant_member)
    @pending_merchant = merchants(:pending_merchant)

    @rejected_merchant_member = members(:rejected_merchant_member)
    @rejected_merchant = merchants(:rejected_merchant)

    @product = products(:one)
  end

  test "approved merchant can access new product page" do
    sign_in @approved_merchant_member

    get new_product_path
    assert_response :success
  end

  test "approved merchant can create product" do
    sign_in @approved_merchant_member

    assert_difference("Product.count", 1) do
      post products_path, params: {
        product: {
          name: "新商品",
          description: "測試描述",
          price: 100,
          stock: 10
        }
      }
    end

    assert_redirected_to products_path
    assert_equal "商品建立成功", flash[:notice]
  end

  test "approved merchant can access edit product page" do
    sign_in @approved_merchant_member

    get edit_product_path(@product)
    assert_response :success
  end

  test "approved merchant can update product" do
    sign_in @approved_merchant_member

    patch product_path(@product), params: {
      product: { name: "更新後的名稱" }
    }

    assert_redirected_to products_path
    assert_equal "商品更新成功", flash[:notice]
    @product.reload
    assert_equal "更新後的名稱", @product.name
  end

  test "pending merchant cannot access new product page" do
    sign_in @pending_merchant_member

    get new_product_path
    assert_redirected_to products_path
    assert_equal "您的商家帳號尚未通過審核，無法進行此操作", flash[:alert]
  end

  test "pending merchant cannot create product" do
    sign_in @pending_merchant_member

    assert_no_difference("Product.count") do
      post products_path, params: {
        product: {
          name: "新商品",
          description: "測試描述",
          price: 100,
          stock: 10
        }
      }
    end

    assert_redirected_to products_path
    assert_equal "您的商家帳號尚未通過審核，無法進行此操作", flash[:alert]
  end

  test "pending merchant cannot access edit product page" do
    sign_in @pending_merchant_member

    get edit_product_path(@product)
    assert_redirected_to products_path
    assert_equal "您的商家帳號尚未通過審核，無法進行此操作", flash[:alert]
  end
  test "pending merchant cannot update product" do
    sign_in @pending_merchant_member

    original_name = @product.name
    patch product_path(@product), params: {
      product: { name: "更新後的名稱" }
    }

    assert_redirected_to products_path
    assert_equal "您的商家帳號尚未通過審核，無法進行此操作", flash[:alert]
    @product.reload
    assert_equal original_name, @product.name  # 名稱沒變
  end

  test "rejected merchant cannot create product" do
    sign_in @rejected_merchant_member

    assert_no_difference("Product.count") do
      post products_path, params: {
        product: {
          name: "新商品",
          description: "測試描述",
          price: 100,
          stock: 10
        }
      }
    end

    assert_redirected_to products_path
    assert_equal "您的商家帳號尚未通過審核，無法進行此操作", flash[:alert]
  end

  test "pending merchant can view their products index" do
    sign_in @pending_merchant_member

    get products_path
    assert_response :success
  end

  test "rejected merchant can view their products index" do
    sign_in @rejected_merchant_member

    get products_path
    assert_response :success
  end
end
