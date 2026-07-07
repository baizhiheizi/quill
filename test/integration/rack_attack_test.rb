# frozen_string_literal: true

require "test_helper"

# Rack::Attack lives in the middleware stack, so we exercise it through the
# full integration stack. The test environment ships with `:null_store` as the
# cache, which silently no-ops `increment` — so we swap in a `MemoryStore` for
# Rack::Attack only for the duration of these tests.
class RackAttackTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  test "throttles POST /admin/login after 5 attempts in 20s" do
    5.times { post "/admin/login", params: { name: "x", password: "y" } }
    # The first 5 must NOT be throttled (they return a redirect for bad creds).
    assert_not_equal 429, response.status

    post "/admin/login", params: { name: "x", password: "y" }
    assert_equal 429, response.status
    assert_not_nil response.headers["Retry-After"]
  end

  test "throttles OAuth callback after 10 hits in 1min" do
    10.times { get "/auth/mixin/callback" }
    get "/auth/mixin/callback"
    assert_equal 429, response.status
  end

  test "throttles API by access token and returns JSON" do
    token = access_tokens(:reader_token)
    300.times { get "/api/articles", headers: { "HTTP_X_ACCESS_TOKEN" => token.value } }
    get "/api/articles", headers: { "HTTP_X_ACCESS_TOKEN" => token.value }
    assert_equal 429, response.status
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_equal "rate_limited", JSON.parse(response.body)["error"]
    assert_not_nil response.headers["Retry-After"]
  end

  test "throttles search after 20 requests in 1min" do
    20.times { get "/search", params: { query: "x" } }
    get "/search", params: { query: "x" }
    assert_equal 429, response.status
  end
end
