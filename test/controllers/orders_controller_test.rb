require "test_helper"

class OredersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get oreders_new_url
    assert_response :success
  end

  test "should get create" do
    get oreders_create_url
    assert_response :success
  end

  test "should get show" do
    get oreders_show_url
    assert_response :success
  end
end
