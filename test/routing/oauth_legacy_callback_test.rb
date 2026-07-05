# frozen_string_literal: true

require "test_helper"

class OauthLegacyCallbackTest < ActionDispatch::IntegrationTest
  test "legacy oauth mixin callback redirects to canonical callback preserving query string" do
    get "/oauth/mixin/callback", params: { code: "abc", state: "xyz" }

    assert_redirected_to "/auth/mixin/callback?code=abc&state=xyz"
  end
end
