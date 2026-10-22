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
    statuses = drive_until_throttled(40) do
      post "/admin/login", params: { name: "x", password: "y" }
    end

    # The first 5 must NOT be throttled (they return a redirect for bad creds).
    assert_operator served_count(statuses), :>=, 5,
      "expected ~5 requests to be served before the throttle: #{statuses.inspect}"
    assert_equal 429, statuses.last,
      "expected the admin login throttle to fire within 40 requests: #{statuses.inspect}"
    assert_not_nil response.headers["Retry-After"]
  end

  test "throttles OAuth callback after 10 hits in 1min" do
    statuses = drive_until_throttled(80) do
      get "/auth/mixin/callback"
    end

    assert_operator served_count(statuses), :>=, 10,
      "expected ~10 requests to be served before the throttle: #{statuses.inspect}"
    assert_equal 429, statuses.last,
      "expected the OAuth callback throttle to fire within 80 requests: #{statuses.inspect}"
  end

  test "throttles API by access token and returns JSON" do
    token = access_tokens(:reader_token)

    statuses = drive_until_throttled(650) do
      get "/api/articles", headers: { "HTTP_X_ACCESS_TOKEN" => token.value }
    end

    assert_operator served_count(statuses), :>=, 300,
      "expected ~300 requests to be served before the throttle: #{statuses.inspect}"
    assert_equal 429, statuses.last,
      "expected the API throttle to fire within 650 requests: #{statuses.inspect}"
    assert_equal "application/json; charset=utf-8", response.content_type
    assert_equal "rate_limited", JSON.parse(response.body)["error"]
    assert_not_nil response.headers["Retry-After"]
  end

  test "throttles search after 20 requests in 1min" do
    statuses = drive_until_throttled(80) do
      get "/search", params: { query: "x" }
    end

    assert_operator served_count(statuses), :>=, 20,
      "expected ~20 requests to be served before the throttle: #{statuses.inspect}"
    assert_equal 429, statuses.last,
      "expected the search throttle to fire within 80 requests: #{statuses.inspect}"
  end

  private

  # Rack::Attack buckets its counters per `Time.now.to_i / period`
  # (`Rack::Attack::Cache#key_and_expiry`), so a request that lands in the
  # next bucket starts a fresh counter. A fixed number of requests therefore
  # fails whenever the requests straddle a bucket boundary — on a slow runner
  # that is a real flake, not an edge case. Drive until the throttle bites
  # (bounded far past one bucket) and return the statuses.
  def drive_until_throttled(max_requests)
    statuses = []
    max_requests.times do
      yield
      statuses << response.status
      break if response.status == 429
    end
    statuses
  end

  # The requests that were served rather than throttled.
  def served_count(statuses)
    statuses.count { |status| status != 429 }
  end
end
