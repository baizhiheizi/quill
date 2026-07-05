# frozen_string_literal: true

require "test_helper"

class Oauth::CallbacksControllerTest < IntegrationTestCase
  MIXIN_USER_ID = "e5555555-5555-5555-8555-555555555555"
  IDENTITY_NUMBER = "70001"

  setup do
    OmniAuth.config.test_mode = true
    UserAuthorization.where(provider: :mixin).destroy_all
    User.where(uid: [ IDENTITY_NUMBER ]).destroy_all
    @callback_headers = { "HTTP_USER_AGENT" => "OAuthCallbacksControllerTest" }
    @auth_hash = OmniAuth::AuthHash.new(
      provider: "mixin",
      uid: IDENTITY_NUMBER,
      credentials: OmniAuth::AuthHash.new(token: "fake-token"),
      extra: {
        raw_info: {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Mixin Reader",
          "biography" => "Hi from Mixin"
        }
      }
    )
    OmniAuth.config.mock_auth[:mixin] = @auth_hash
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:mixin] = nil
  end

  test "callback creates a new user and session" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { Session.count }, 1 do
        get "/auth/mixin/callback", params: { provider: "mixin" }, headers: @callback_headers
      end
    end

    user = User.find_by!(uid: IDENTITY_NUMBER)
    assert_equal "Mixin Reader", user.name
    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("connected"), flash[:success]

    session_record = Session.order(:created_at).last
    assert_equal user.id, session_record.user_id
    assert session_record.info["ip"].present?
    assert session_record.info.with_indifferent_access[:user_agent].present?
  end

  test "callback reuses existing user" do
    existing = User.create!(
      name: "Existing",
      mixin_id: IDENTITY_NUMBER,
      mixin_uuid: MIXIN_USER_ID,
      uid: IDENTITY_NUMBER
    )
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      access_token: "old",
      raw: { "user_id" => MIXIN_USER_ID, "identity_number" => IDENTITY_NUMBER },
      user: existing
    )

    assert_no_difference -> { User.count } do
      get "/auth/mixin/callback", params: { provider: "mixin" }, headers: @callback_headers
    end

    assert_redirected_to root_path
  end

  test "callback honors internal return_to from omniauth params" do
    article = articles(:published_paid)
    return_to = user_article_path(article.author, article)

    get "/auth/mixin/callback",
        params: { provider: "mixin", return_to: return_to },
        headers: @callback_headers

    assert_redirected_to return_to
  end

  test "callback rejects external return_to" do
    get "/auth/mixin/callback",
        params: { provider: "mixin", return_to: "https://evil.example/phish" },
        headers: @callback_headers

    assert_redirected_to root_path
  end

  test "failure redirects unsigned with failed_to_connect flash" do
    get "/auth/failure", params: { message: "access_denied", strategy: "mixin" }

    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("failed_to_connect"), flash[:alert]
    assert_nil session[:current_session_id]
  end

  test "failure preserves safe return_to" do
    article = articles(:published_paid)
    return_to = user_article_path(article.author, article)

    get "/auth/failure",
        params: { message: "access_denied", strategy: "mixin", return_to: return_to },
        headers: @callback_headers

    assert_redirected_to return_to
  end

  test "callback handles missing auth hash as failure" do
    OmniAuth.config.mock_auth[:mixin] = nil

    assert_no_difference -> { Session.count } do
      get "/auth/mixin/callback", params: { provider: "mixin" }, headers: @callback_headers
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("failed_to_connect"), flash[:alert]
  end

  test "callback handles rate limit errors" do
    rate_limit_error = MixinBot::RateLimitError.new(
      code: 429,
      description: "Too Many Requests",
      verb: "GET",
      path: "/oauth/token"
    )
    original = Oauth::SignIn.method(:call)
    Oauth::SignIn.define_singleton_method(:call) { |**| raise rate_limit_error }
    begin
      assert_no_difference -> { Session.count } do
        get "/auth/mixin/callback", params: { provider: "mixin" }, headers: @callback_headers
      end
    ensure
      Oauth::SignIn.define_singleton_method(:call, original)
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("mixin_rate_limited"), flash[:alert]
  end

  test "callback handles sign in errors" do
    original = Oauth::SignIn.method(:call)
    Oauth::SignIn.define_singleton_method(:call) { |**| raise Oauth::SignInError, "invalid" }
    begin
      assert_no_difference -> { Session.count } do
        get "/auth/mixin/callback", params: { provider: "mixin" }, headers: @callback_headers
      end
    ensure
      Oauth::SignIn.define_singleton_method(:call, original)
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("failed_to_connect"), flash[:alert]
  end

  test "callback invokes login notification" do
    original = DeliveryMethods::MixinBot.instance_method(:deliver)
    DeliveryMethods::MixinBot.define_method(:deliver) { |_| true }
    begin
      assert_difference -> { Noticed::Event.count }, 1 do
        get "/auth/mixin/callback", params: { provider: "mixin" }, headers: @callback_headers
      end
    ensure
      DeliveryMethods::MixinBot.define_method(:deliver, original)
    end
  end
end
