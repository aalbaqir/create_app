require "test_helper"

class MediaControllerTest < ActionDispatch::IntegrationTest
  test "should get upload" do
    get media_upload_url
    assert_response :success
  end
end
