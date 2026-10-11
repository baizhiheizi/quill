# frozen_string_literal: true

require "test_helper"

class Dashboard::NotificationSettingsControllerTest < ActionController::TestCase
  tests Dashboard::NotificationSettingsController

  setup do
    @user = users(:reader_one)
    @setting = ensure_notification_setting!(@user)
    session[:current_session_id] = sign_in(@user).uuid
  end

  test "update persists permitted notification settings" do
    patch :update, params: {
      id: @setting.id,
      notification_setting: {
        article_published_web: "0",
        transfer_processed_mixin_bot: "0"
      }
    }, format: :turbo_stream

    assert_response :success
    @setting.reload
    assert_equal false, @setting.article_published_web
    assert_equal false, @setting.transfer_processed_mixin_bot
  end

  test "update persists the toggles of a newly declared kind" do
    patch :update, params: {
      id: @setting.id,
      notification_setting: {
        collection_bought_web: "0",
        collection_listed_mixin_bot: "0"
      }
    }, format: :turbo_stream

    assert_response :success
    @setting.reload
    assert_equal false, @setting.collection_bought_web
    assert_equal false, @setting.collection_listed_mixin_bot
  end

  test "update ignores unpermitted notification setting fields" do
    patch :update, params: {
      id: @setting.id,
      notification_setting: {
        article_published_web: "0",
        user_id: users(:author).id,
        webhook_url: "https://example.com/changed"
      }
    }, format: :turbo_stream

    assert_response :success
    @setting.reload
    assert_equal false, @setting.article_published_web
    assert_equal @user.id, @setting.user_id
    assert_nil @setting.read_attribute(:webhook)
  end

  test "update redirects unauthenticated access to login" do
    @setting.update! article_published_web: false
    session.delete(:current_session_id)

    patch :update, params: {
      id: @setting.id,
      notification_setting: { article_published_web: "1" }
    }, format: :turbo_stream

    assert_redirected_to login_path(return_to: URI.encode_www_form_component("/dashboard"))
    assert_equal false, @setting.reload.article_published_web
  end
end
