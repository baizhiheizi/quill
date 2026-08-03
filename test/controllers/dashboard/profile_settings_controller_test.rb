# frozen_string_literal: true

require "test_helper"

# `Dashboard::ProfileSettingsController` exposes a single `update` action
# that whitelists `name`, `biography`, `avatar`, and `email`; the public
# `verify_email` action (no authentication required) consumes a one-shot
# verification code stored in `Rails.cache` by `Users::EmailVerifiable`.
class Dashboard::ProfileSettingsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper
  tests Dashboard::ProfileSettingsController

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache
  end

  # --- edit -------------------------------------------------------------

  test "edit is reachable for the current user" do
    get :edit

    assert_response :success
  end

  test "edit redirects unauthenticated requests to login" do
    session.delete(:current_session_id)

    get :edit

    assert_response :redirect
    assert_match %r{/login}, response.location
  end

  # --- update -----------------------------------------------------------

  test "update persists permitted profile fields" do
    patch :update, params: {
      user: { name: "Renamed Author", biography: "First bio" }
    }, format: :turbo_stream

    assert_response :success
    @user.reload
    assert_equal "Renamed Author", @user.name
    assert_equal "First bio", @user.biography
  end

  test "update ignores unpermitted fields" do
    original_uid = @user.uid
    original_mixin = @user.mixin_id

    patch :update, params: {
      user: {
        name: "Still Renamed",
        uid: "HACKED",
        mixin_id: "HACKED",
        locale: "ja"
      }
    }, format: :turbo_stream

    assert_response :success
    @user.reload
    assert_equal "Still Renamed", @user.name
    assert_equal original_uid, @user.uid
    assert_equal original_mixin, @user.mixin_id
    assert_equal "en", @user.locale
  end

  test "update is a no-op when no user params are provided" do
    original_name = @user.name

    patch :update, params: { user: {} }, format: :turbo_stream

    assert_response :success
    @user.reload
    assert_equal original_name, @user.name
  end

  test "update triggers email verification when email changes" do
    assert_emails(1) do
      perform_enqueued_jobs do
        patch :update, params: {
          user: { name: @user.name, email: "newauthor@example.test" }
        }, format: :turbo_stream
      end
    end

    assert_response :success
    @user.reload
    assert_equal "newauthor@example.test", @user.email
    assert_nil @user.email_verified_at
  end

  test "update does not re-verify when email is unchanged" do
    @user.update_columns(email: "fixed@example.test", email_verified_at: 1.day.ago)

    assert_no_emails do
      perform_enqueued_jobs do
        patch :update, params: {
          user: { name: "Renamed Again", email: "fixed@example.test" }
        }, format: :turbo_stream
      end
    end

    assert_response :success
    @user.reload
    assert_equal "Renamed Again", @user.name
    assert_not_nil @user.email_verified_at
  end

  test "update redirects unauthenticated requests to login" do
    session.delete(:current_session_id)
    original_name = @user.name

    patch :update, params: {
      user: { name: "Should Not Persist" }
    }, format: :turbo_stream

    assert_response :redirect
    assert_match %r{/login}, response.location
    assert_equal original_name, @user.reload.name
  end

  # --- verify_email -----------------------------------------------------

  test "verify_email consumes a valid cached code and marks the email as verified" do
    new_email = "verified@example.test"
    @user.update_columns(email: new_email)
    Rails.cache.write "verify-code-1", new_email

    get :verify_email, params: { code: "verify-code-1" }

    assert_response :success
    assert_match "has been verified", response.body
    assert @user.reload.email_verified?
    assert_nil Rails.cache.read("verify-code-1")
  end

  test "verify_email renders failure UI for a missing code" do
    @user.update_columns(email: "unverified@example.test")

    get :verify_email, params: { code: "no-such-code" }

    assert_response :success
    assert_match "Cannot verify", response.body
    assert_not @user.reload.email_verified?
  end

  test "verify_email does not require authentication" do
    session.delete(:current_session_id)
    new_email = "noauth@example.test"
    @user.update_columns(email: new_email)
    Rails.cache.write "verify-code-2", new_email

    get :verify_email, params: { code: "verify-code-2" }

    assert_response :success
    assert @user.reload.email_verified?
  end
end
