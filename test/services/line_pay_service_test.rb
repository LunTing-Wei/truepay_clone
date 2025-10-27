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
end
