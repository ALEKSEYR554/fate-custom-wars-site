require "test_helper"

class RandomizerControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get randomizer_index_url
    assert_response :success
  end
end
