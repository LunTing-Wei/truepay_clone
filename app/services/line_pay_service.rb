class LinePayService
  include HTTParty

  base_uri ENV.fetch('LINE_PAY_SANDBOX_URL') { Rails.application.credentials.line_pay[:sandbox_url] }

  def initialize
    @channel_id = ENV.fetch('LINE_PAY_CHANNEL_ID') { Rails.application.credentials.line_pay[:channel_id] }
    @channel_secret = ENV.fetch('LINE_PAY_CHANNEL_SECRET') { Rails.application.credentials.line_pay[:channel_secret] }
  end

  def request_payment(order)
    # 從 action_controller 設定讀取 URL options（包含 host 和 protocol）
    url_options = Rails.application.config.action_controller.default_url_options

    confirm_url = Rails.application.routes.url_helpers.linepay_confirm_order_url(order, **url_options)
    cancel_url = Rails.application.routes.url_helpers.order_url(order, **url_options)

    request_body = {
      amount: order.amount.to_i,
      currency: "TWD",
      orderId: order.id.to_s,
      packages: [
        {
          id: "package_#{order.id}",
          amount: order.amount.to_i,
          products: [
            {
              name: order.product.name,
              quantity: order.quantity,
              price: order.unit_price.to_i
            }
          ]
        }
      ],
      redirectUrls: {
        confirmUrl: confirm_url,
        cancelUrl: cancel_url
      }
    }

    # 轉成 JSON 並生成簽章
    request_body_json = request_body.to_json
    uri = '/v3/payments/request'
    nonce = SecureRandom.uuid
    signature = generate_signature(uri, request_body_json, nonce)

    response = self.class.post(
      uri,
      body: request_body_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-LINE-ChannelId' => @channel_id,
        'X-LINE-Authorization-Nonce' => nonce,
        'X-LINE-Authorization' => signature
      }
    )

    Rails.logger.info "LINE Pay request - Order: #{order.id}, Amount: #{order.amount}"
    Rails.logger.info "LINE Pay response - Code: #{response.code}, ReturnCode: #{response['returnCode']}"

    # 處理回應
    if response.code == 200 && response['returnCode'] == '0000'
      {
        success: true,
        transaction_id: response['info']['transactionId'],
        payment_url: response['info']['paymentUrl']['web']
      }
    else
      Rails.logger.error "LINE Pay request failed - ReturnCode: #{response['returnCode']}, Message: #{response['returnMessage']}"
      {
        success: false,
        error_message: response['returnMessage'] || 'Unknown error'
      }
    end
  rescue HTTParty::Error, Timeout::Error, StandardError => e
    Rails.logger.error "LINE Pay request exception - #{e.class}: #{e.message}"
    {
      success: false,
      error_message: "網路錯誤：#{e.message}"
    }
  end

  def confirm_payment(transaction_id, amount)
    uri = "/v3/payments/#{transaction_id}/confirm"
    nonce = SecureRandom.uuid

    request_body = {
      amount: amount,
      currency: "TWD"
    }
    request_body_json = request_body.to_json
    signature = generate_signature(uri, request_body_json, nonce)

    response = self.class.post(
      uri,
      body: request_body_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-LINE-ChannelId' => @channel_id,
        'X-LINE-Authorization-Nonce' => nonce,
        'X-LINE-Authorization' => signature
      }
    )

    Rails.logger.info "LINE Pay confirm - TransactionId: #{transaction_id}, Amount: #{amount}"
    Rails.logger.info "LINE Pay confirm response - Code: #{response.code}, ReturnCode: #{response['returnCode']}"

    if response.code == 200 && response['returnCode'] == '0000'
      true
    else
      Rails.logger.error "LINE Pay confirm failed - TransactionId: #{transaction_id}, ReturnCode: #{response['returnCode']}, Message: #{response['returnMessage']}"
      false
    end
  rescue HTTParty::Error, Timeout::Error, StandardError => e
    Rails.logger.error "LINE Pay confirm exception - #{e.class}: #{e.message}"
    false
  end

  private

  def generate_signature(uri, body, nonce)
    message = @channel_secret + uri + body + nonce
    Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', @channel_secret, message))
  end
end