require "test_helper"

class ServantsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get servants_show_url
    assert_response :success
  end
end
