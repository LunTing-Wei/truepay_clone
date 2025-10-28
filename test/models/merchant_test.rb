require "test_helper"

class MerchantTest < ActiveSupport::TestCase
  setup do
    @member = members(:pending_merchant_member)
    @merchant = merchants(:pending_merchant)
  end

  # ========== 測試 auto_approvable? ==========
  test "auto_approvable? should return false when all fields are blank" do
    assert_not @merchant.auto_approvable?, "應該返回 false，因為沒有填寫任何審核資料"
  end

  test "auto_approvable? should return false when some fields are missing" do
    @merchant.update(
      unified_number: "12345678",
      owner_name: "測試負責人",
      phone: "0912345678"
    )

    assert_not @merchant.auto_approvable?, "應該返回 false，因為還有欄位未填寫"
  end

  test "auto_approvable? should return true when all required fields are filled" do
    @merchant.update(
      unified_number: "12345678",
      owner_name: "測試負責人",
      owner_id_last_four: "A123",
      business_address: "台北市大安區測試路123號",
      phone: "0912345678",
      customer_service_email: "service@test.com"
    )

    assert @merchant.auto_approvable?, "應該返回 true，因為所有必填欄位都已填寫"
  end

  # ========== 測試 auto_approve! ==========
  test "auto_approve! should approve merchant when all fields are valid" do
    @merchant.update(
      unified_number: "87654321",
      owner_name: "測試負責人",
      owner_id_last_four: "B456",
      business_address: "台北市信義區測試路456號",
      phone: "0987654321",
      customer_service_email: "contact@test.com"
    )

    assert @merchant.pending?, "執行前應該是 pending"
    assert_nil @merchant.verified_at, "執行前應該沒有審核時間"

    result = @merchant.auto_approve!

    assert result, "auto_approve! 應該返回 true"
    assert @merchant.approved?, "狀態應該變為 approved"
    assert_not_nil @merchant.verified_at, "應該設定審核時間"
    assert_nil @merchant.rejection_reason, "應該清除拒絕原因"
  end

  test "auto_approve! should return false when fields are incomplete" do
    @merchant.update(
      unified_number: "11111111",
      owner_name: "不完整商家"
    )

    result = @merchant.auto_approve!

    assert_not result, "auto_approve! 應該返回 false"
    assert @merchant.pending?, "狀態應該保持 pending"
    assert_nil @merchant.verified_at, "不應該設定審核時間"
  end

  # ========== 測試格式驗證 ==========
  test "should reject invalid unified_number format" do
    @merchant.unified_number = "ABC123"

    assert_not @merchant.valid?, "商家應該無效，因為統編格式錯誤"
    assert @merchant.errors[:unified_number].any?, "應該有 unified_number 的錯誤訊息"
  end

  test "should accept valid unified_number format" do
    @merchant.unified_number = "12345678"

    @merchant.valid?
    assert_not @merchant.errors[:unified_number].any?, "不應該有 unified_number 的錯誤"
  end

  test "should reject invalid phone format" do
    @merchant.phone = "123456"

    @merchant.valid?
    assert @merchant.errors[:phone].any?, "應該有 phone 的錯誤訊息"
  end

  test "should accept valid mobile phone format" do
    @merchant.phone = "0912345678"

    @merchant.valid?
    assert_not @merchant.errors[:phone].any?, "不應該有 phone 的錯誤"
  end

  test "should accept valid landline phone format" do
    @merchant.phone = "02-12345678"

    @merchant.valid?
    assert_not @merchant.errors[:phone].any?, "不應該有 phone 的錯誤"
  end

  test "should reject invalid email format" do
    @merchant.customer_service_email = "invalid_email"

    @merchant.valid?
    assert @merchant.errors[:customer_service_email].any?, "應該有 email 的錯誤訊息"
  end

  test "should accept valid email format" do
    @merchant.customer_service_email = "service@example.com"

    @merchant.valid?
    assert_not @merchant.errors[:customer_service_email].any?, "不應該有 email 的錯誤"
  end

  # ========== 測試唯一性約束 ==========
  test "should reject duplicate unified_number" do
    @merchant.update(unified_number: "99999999")

    member2 = Member.create!(
      email: "duplicate_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      member_type: :merchant
    )

    merchant2 = Merchant.new(
      member: member2,
      shop_name: "重複統編商店",
      subdomain: "duplicate-test-shop",
      unified_number: "99999999"
    )

    assert_not merchant2.valid?, "應該無效，因為統編重複"
    assert merchant2.errors[:unified_number].any?, "應該有 unified_number 的錯誤訊息"
  end
end
