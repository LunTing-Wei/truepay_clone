require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  #setup
  setup do
    @member = members(:one)
    sign_in @member

    @product = products(:one)
    @customer = @member.customer
    @order = orders(:pending_order)
  end

  # Test: GET /orders/new
  test "should get new order page when logged in" do
    get new_order_path, params: {product_id: @product.id}
    assert_response :success
    assert_select 'h1', '訂單確認'
  end

  #Test: POST /orders (建立訂單)
  test "should create order with valid params" do 
    assert_difference('Order.count',1) do
      post orders_path, params: {
        order:{
          product_id: @product.id,
          quantity: 2
        }
      }
    end

    assert_redirected_to order_path(Order.last)
    assert_equal '訂單建立成功，請前往付款', flash[:notice]
  end

  # Test: GET /orders/:id
  test "should show order when user owns it" do
    get order_path(@order)
    assert_response :success
  end

  #邊界測試
  # Test: 未登入使用者不能訪問
  test "should redirect to login when not logged in" do
    sign_out @member

    get new_order_path, params: {product_id: @product.id}
    assert_redirected_to "https://test.example.com/members/sign_in"
  end

  # Test: 不能訪問別人的訂單
  test "should not show order owned by another user" do
    other_customer = customers(:two)
    other_order = Order.create!(
      customer: other_customer,
      product: @product,
      quantity: 1,
      unit_price: @product.price,
      amount: @product.price,
      status: :pending
    )

    get order_path(other_order)
    assert_redirected_to root_path
    assert_equal '無權操作此訂單', flash[:alert]
  end

  # Test: 已付款的訂單不能再付款
  test "should not allow payment for already paid order" do
    paid_order = orders(:paid_order)

    post pay_order_path(paid_order)
    assert_redirected_to order_path(paid_order)
    assert_equal '此訂單無法付款', flash[:alert]
  end
  # LINE Pay 測試
  # Test: LINE Pay request 成功
  test "should request LINE Pay payment successfully" do
    # Mock LINE Pay API 回傳成功
    stub_request(:post, "https://sandbox-api-pay.line.me/v3/payments/request")
      .to_return(
        status: 200,
        body: {
          returnCode: '0000',
          returnMessage: 'Success',
          info:{
            transactionId: 123456789,
            paymentUrl:{
              web: 'https://sandbox-web-pay.line.me/web/payment/wait?transactionReserveId=test123'
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      post linepay_request_order_path(@order)

      assert_redirected_to 'https://sandbox-web-pay.line.me/web/payment/wait?transactionReserveId=test123'

      @order.reload
      assert_equal "123456789", @order.transaction_id
      assert_equal 'linepay', @order.provider
  end

  # Test: LINE Pay request 失敗
  test "should handle LINE Pay request failure" do
    # Mock LINE Pay API 回傳失敗
    stub_request(:post, "https://sandbox-api-pay.line.me/v3/payments/request")
      .to_return(
        status: 200,
        body: {
          returnCode: '1104',
          returnMessage: 'Merchant not found'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    post linepay_request_order_path(@order)

    assert_redirected_to order_path(@order)
    assert_equal 'LINE Pay 請求失敗：Merchant not found', flash[:alert]
  end
end
