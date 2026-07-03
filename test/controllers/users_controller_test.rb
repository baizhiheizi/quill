# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < IntegrationTestCase
  test "show renders the public profile" do
    user = users(:author)

    get user_path(user)

    assert_response :success
    assert_match user.name, response.body
  end

  # FR-008 / SC-007: the public profile must never surface earnings or
  # on-chain financial figures, only modest public stats (post count,
  # subscriber count, join date).
  test "show never renders earnings or revenue figures" do
    user = users(:author)

    get user_path(user)

    assert_response :success
    assert_no_match(/revenue|earning/i, response.body)
  end
end
