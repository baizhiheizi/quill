# frozen_string_literal: true

require "test_helper"

class AccessTokenTest < ActiveSupport::TestCase
  test "resolves user for API auth" do
    token = access_tokens(:reader_token)

    assert_equal users(:reader_one), AccessToken.kept.find_by(value: token.value).user
  end

  test "soft-deleted tokens are excluded from kept scope" do
    token = access_tokens(:reader_token)
    token.update!(deleted_at: Time.current)

    assert_nil AccessToken.kept.find_by(value: token.value)
  end

  test "generates value on initialize" do
    token = AccessToken.new(user: users(:reader_one), memo: "new token")

    assert_predicate token.value, :present?
  end
end
