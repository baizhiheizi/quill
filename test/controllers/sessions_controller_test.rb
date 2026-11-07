# frozen_string_literal: true

require "test_helper"

# `SessionsController#twitter` is currently unreachable through the HTTP
# router: the omniauth catch-all `match "/auth/:provider/callback"` is
# defined before `get "auth/twitter/callback"`, so Twitter's redirect
# lands in `Oauth::CallbacksController#create` (pinned by the routing
# test in `test/routing/`). Re-ordering those routes is a maintainer
# decision; these tests pin the handler's guard behavior for the day the
# route goes live, including the blank cache keys that used to 500.
class SessionsControllerTest < ActionController::TestCase
  tests SessionsController

  setup do
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache
  end

  test "twitter redirects to root when the state param is absent" do
    get :twitter

    assert_redirected_to root_path
  end

  test "twitter redirects to root for a state that has no cached auth" do
    get :twitter, params: { state: "unknown-state" }

    assert_redirected_to root_path
  end

  test "twitter redirects to root when the cached auth names no user" do
    Rails.cache.write "orphan-state", { code_verifier: "verifier", uid: "no-such-uid" }

    get :twitter, params: { state: "orphan-state" }

    assert_redirected_to root_path
  end
end
