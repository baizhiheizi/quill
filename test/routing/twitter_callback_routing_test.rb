# frozen_string_literal: true

require "test_helper"

# Pins the live routing for Twitter's callback: the omniauth catch-all
# `match "/auth/:provider/callback"` (config/routes.rb) is defined BEFORE
# `get "auth/twitter/callback"`, so `/auth/twitter/callback` is handled
# by `Oauth::CallbacksController#create` and `SessionsController#twitter`
# never runs. Re-ordering the routes to revive the Twitter connect flow
# is a deliberate maintainer decision; this test makes that re-ordering
# visible instead of silent.
class TwitterCallbackRoutingTest < ActionController::TestCase
  test "the omniauth catch-all shadows sessions#twitter for /auth/twitter/callback" do
    assert_recognizes(
      { controller: "oauth/callbacks", action: "create", provider: "twitter" },
      "/auth/twitter/callback"
    )
  end
end
