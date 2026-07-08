# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for the per-user access-token cap. Uses
# `ActionController::TestCase` (like PreOrdersCreateControllerTest) so the
# session can be set directly via `session[:current_session_id]`.
class Dashboard::AccessTokensControllerTest < ActionController::TestCase
  tests Dashboard::AccessTokensController

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "create within the cap succeeds and prepends the token" do
    assert_difference -> { @user.access_tokens.kept.count }, 1 do
      post :create, params: { access_token: { memo: "cap test" } }, format: :turbo_stream
    end

    assert_response :success
  end

  test "create past the cap returns unprocessable_entity and surfaces the error" do
    # Fill to the cap (author already has 1 fixture token).
    (AccessToken.per_user_limit - @user.access_tokens.kept.count).times do
      AccessToken.create!(user: @user, memo: "filler", value: SecureRandom.uuid)
    end

    assert_no_difference -> { @user.access_tokens.kept.count } do
      post :create, params: { access_token: { memo: "one too many" } }, format: :turbo_stream
    end

    assert_response :unprocessable_entity
    # The translated error message renders in the modal slot.
    assert_match(/reached the limit/i, response.body)
  end
end
