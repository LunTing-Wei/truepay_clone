require "test_helper"

class LinePayServiceTest < ActiveSupport::TestCase
  setup do
    @service = LinePayService.new

    @order = orders(:pending_order)
  end

  test "request_payment should return success when Line Pay API succeeds" do
    stub_request(:post, %r{/v3/payments/request})
      .to_return(
        status: 200,
        body: {
          returnCode: "0000",
          returnMessage: "Success",
          info: {
            transactionId: 123456789,
            paymentUrl: {
              web: "https://sandbox-web-pay.line.me/web/payment/wait?transactionReserveId=eVBIli57zpXA7cWGpDRdTHGxqy5wV3bBJXVE03zvfiQ="
            }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    result = @service.request_payment(@order)

    assert result[:success], "Expected success to be true"
    assert_equal 123456789, result[:transaction_id]
    assert_includes result[:payment_url], "https://sandbox-web-pay.line.me"
  end

  test "request_payment should return error when LINE Pay API returns error code" do
    stub_request(:post, %r{/v3/payments/request})
     .to_return(
      status: 200,
      body: {
        returnCode: "1150",
        returnMessage: "Transaction not found"
      }.to_json,
      headers: { "Content-Type" => "application/json" }
     )

    result = @service.request_payment(@order)

    assert_not result[:success], "Expected success to be false"
    assert_equal "Transaction not found", result[:error_message]
    assert_nil result[:transaction_id]
  end

  test "request_payment should handle network timeout" do
    stub_request(:post, %r{/v3/payments/request})
     .to_timeout
    result = @service.request_payment(@order)

    assert_not result[:success], "Expected success to be false"
    assert_includes result[:error_message], "網路錯誤"
  end
  # 測試 confirm_payment 成功
  test "confirm_payment should return success when LINE Pay confirms payment" do
    transaction_id = "2024012312345678"
    amount = 200

    stub_request(:post, %r{/v3/payments/#{transaction_id}/confirm})
     .to_return(
      status: 200,
      body: {
        returnCode: "0000",
        returnMessage: "Success",
        info: {
          orderId: @order.id.to_s,
          transactionId: transaction_id
        }
      }.to_json,
      headers: { "Content-Type" => "application/json" }
     )
    result = @service.confirm_payment(transaction_id, amount)

    assert result[:success], "Expected success to be true"
    assert_equal transaction_id, result[:transaction_id]
  end
  # 測試 confirm_payment 失敗
  test "confirm_payment should return error when LINE Pay returns error" do
    transaction_id = "invalid_txn"
    amount = 200

    stub_request(:post, %r{/v3/payments/#{transaction_id}/confirm})
      .to_return(
        status: 200,
        body: {
          returnCode: "1198",
          returnMessage: "Duplicate request"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    result = @service.confirm_payment(transaction_id, amount)

    assert_not result[:success], "Expected success to be false"
    assert_equal "1198", result[:error_code]
    assert_equal "Duplicate request", result[:error_message]
  end

  # 測試 confirm_payment 網路異常
  test "confirm_payment should handle network errors" do
    transaction_id = "test_txn"
    amount = 200

    stub_request(:post, %r{/v3/payments/#{transaction_id}/confirm})
     .to_raise(StandardError.new("Connection refused"))
    result = @service.confirm_payment(transaction_id, amount)

    assert_not result[:success], "Expected success to be false"
    assert_includes result[:error_message], "網路錯誤"
  end
end
