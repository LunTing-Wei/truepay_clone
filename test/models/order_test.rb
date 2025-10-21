require "test_helper"

class OrderTest < ActiveSupport::TestCase
  #setup
  setup do
    @customer = customers(:one)
    @product = products(:one)
    @order = Order.new(
      customer: @customer,
      product: @product,
      quantity: 2,
      unit_price: 100,
      status: :pending
    )
  end
  # Test: 金額自動計算
  test "should generate tickets when order becomes paid" do
    @order.save!
    assert_equal 0, @order.items.count

    assert_difference '@order.items.count', 2 do
      @order.update!(status: :paid)
    end
    @order.items.each do |ticket|
      assert_equal @product, ticket.product
      assert_equal @customer, ticket.customer
      assert_not_nil ticket.valid_until
      assert ticket.unused?
    end
  end

  # Test: 防止重複生成票券
  test "should not generate tickets if already exists" do
    @order.save!
    @order.update!(status: :paid)

    initial_count = @order.items.count
    assert_equal 2, initial_count

    assert_no_difference '@order.items.count' do
      @order.update!(paid_at: Time.current)
    end
  end

  # Test: 只有狀態變成 paid 才生成票券
  test "should only generate tickets when status changes to paid" do
    @order.save!
    assert_no_difference '@order.items.count' do
      @order.update!(status: :failed)
    end
    assert_difference '@order.items.count', 2 do
      @order.update!(status: :paid)
    end
  end

  # Test: Validations
  test "should require quantity" do
    @order.quantity = nil
    assert_not @order.valid?
    assert_includes @order.errors[:quantity], "can't be blank"
  end

  test "should require positive quantity" do
    @order.quantity = 0
    assert_not @order.valid?
    assert_includes @order.errors[:quantity], "must be greater than 0"
  end
end
