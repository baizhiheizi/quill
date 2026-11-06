# frozen_string_literal: true

require "test_helper"

class IntegrationTestCase < ActionDispatch::IntegrationTest
  include CommerceHelpers
  include QuillBotStub

  # Signs `user` in by driving the real mixin OAuth callback with OmniAuth's
  # test mode, so the session cookie in the integration cookie jar is produced
  # by the actual sign-in path. Writing `session[:current_session_id]`
  # directly does NOT persist: in an integration test `session` wraps the
  # *last* request's env, and the value never reaches the cookie jar, which
  # silently turned every signed-in integration test into a guest visit.
  def sign_in(user)
    host! "www.example.com"

    raw = {
      "user_id" => user.mixin_uuid,
      "identity_number" => user.uid,
      "full_name" => user.name,
      "biography" => user.biography.to_s
    }
    # The callback reuses the authorization bound to the fixture user; without
    # it `Oauth::SignIn` would try to create a second user with the same uid.
    UserAuthorization.create_with(
      user: user,
      raw: raw,
      access_token: "integration-access-token"
    ).find_or_create_by!(provider: :mixin, uid: user.mixin_uuid).update!(
      user: user,
      raw: raw,
      access_token: "integration-access-token"
    )

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:mixin] = OmniAuth::AuthHash.new(
      provider: "mixin",
      uid: user.mixin_uuid,
      credentials: OmniAuth::AuthHash.new(token: "integration-access-token"),
      extra: { raw_info: raw }
    )

    get "/auth/mixin/callback", params: { provider: "mixin" }

    unless session[:current_session_id].present?
      raise "IntegrationTestCase#sign_in failed: status #{status}, body: #{response.body.truncate(300)}"
    end

    user.sessions.order(:created_at).last
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:mixin] = nil
  end
end
