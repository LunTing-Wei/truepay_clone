require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_member = members(:one)
    @customer = @customer_member.customer

    @merchant_member = members(:merchant_one)
    @merchant = merchants(:one)

    @product = products(:one)
    @paid_order = orders(:paid_order)

    if @paid_order.items.empty?
      @paid_order.quantity.times do
        @paid_order.items.create!(
          product: @paid_order.product,
          customer: @paid_order.customer,
          valid_until: 180.days.from_now,
          status: :unused
        )
      end
    end
    @ticket = @paid_order.items.first
  end
  #消費者功能測試
  
  test "customer should see their tickets on index page" do
    sign_in @customer_member

    get tickets_path
    assert_response :success
  end
  
  test "merchant cannot access customer tickets index" do
    sign_in @merchant_member

    get tickets_path
    assert_redirected_to products_path
    assert_equal '此頁面僅限消費者訪問', flash[:alert]
  end
  #商家核銷功能測試
  test "merchant should access scan page" do
    sign_in @merchant_member

    get scan_tickets_path
    assert_response :success
  end

  test "customer cannot access scan page" do
    sign_in @customer_member

    get scan_tickets_path
    assert_redirected_to root_path
    assert_equal '此頁面僅限商家訪問', flash[:alert]
  end

  test "should verify ticket successfully" do
    sign_in @merchant_member
    @ticket.update!(status: :unused)
    post verify_tickets_path, params: { ticket_code: @ticket.ticket_code }, as: :json

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal '核銷成功', json_response['message']

    @ticket.reload
    assert @ticket.used?
    assert_not_nil @ticket.used_at
  end
  
  test "should reject invalid ticket code" do
    sign_in @merchant_member

    post verify_tickets_path, params: { ticket_code: 'INVALID_CODE' }, as: :json
    
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal '票券不存在', json_response['error']
  end

  test "should reject ticket from another merchant" do
    other_merchant_member = Member.create!(
        email: 'other_merchant@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        member_type: :merchant
      )
      other_merchant = Merchant.create!(
        member: other_merchant_member,
        shop_name: 'Other Shop',
        subdomain: 'other'
      )
      other_product = Product.create!(
        merchant: other_merchant,
        name: 'Other Product',
        price: 100,
        stock: 10
      )

      # 創建訂單並手動生成票券
      other_order = Order.create!(
        customer: @customer,
        product: other_product,
        quantity: 1,
        unit_price: 100,
        amount: 100,
        status: :paid
      )
      other_ticket = other_order.items.create!(
        product: other_product,
        customer: @customer,
        valid_until: 180.days.from_now,
        status: :unused
      )

      sign_in @merchant_member

      post verify_tickets_path, params: { ticket_code: other_ticket.ticket_code }, as: :json

      assert_response :forbidden
      json_response = JSON.parse(response.body)
      assert_not json_response['success']
      assert_equal '無權核銷此票券', json_response['error']
  end

  test "should reject already used ticket" do
    sign_in @merchant_member

    @ticket.update!(status: :used, used_at: 1.hour.ago)

    post verify_tickets_path, params: { ticket_code: @ticket.ticket_code }, as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal '票券已使用', json_response['error']
  end

  test "should reject expired ticket" do
    sign_in @merchant_member

    @ticket.update!(status: :expired, valid_until: 1.day.ago)

    post verify_tickets_path, params: { ticket_code: @ticket.ticket_code }, as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal '票券已過期', json_response['error']
  end
end