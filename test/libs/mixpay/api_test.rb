# frozen_string_literal: true

require "test_helper"

# Covers the `Mixpay::API` facade for the Mixpay HTTP client. The class is
# the thin layer between `Mixpay.api` (the cached singleton in `Mixpay`)
# and the underlying `Mixpay::Client`; it routes each call to a path,
# passes query params / JSON body, and wraps three of the lookups with
# `Rails.cache.fetch` (10-minute TTL).
#
# Why a dedicated file: the existing `client_test.rb` only exercises the
# raw `Mixpay::Client` — connection failure raising `Errors::HttpError`.
# None of the API's path routing, parameter shape, or cache behaviour
# had direct coverage. `pre_orders_controller_test.rb` stubs the API at
# its public surface (`settlement_asset_ids`, `quote_assets_cached`) but
# never asserts what those methods actually pass to the underlying
# client. This file pins:
#
# - `settlement_assets` / `quote_assets` hit `/v1/setting/...` via GET
# - `payments_result` passes `traceId` as a query param
# - `payments_info` passes both `traceId` and `clientId` as query params
# - `multisig` POSTs the `receivers` + `threshold` body as JSON
# - `quote_assets_cached` / `quote_asset_ids` / `settlement_asset_ids`
#   memoize via `Rails.cache.fetch` with a 10-minute TTL, returning the
#   cached value on a hit without re-invoking the client
class Mixpay::APITest < ActiveSupport::TestCase
  # A minimal stand-in for Mixpay::Client that records every request and
  # returns the canned payload its caller queued up. The real client
  # parses JSON responses and unwraps `:success`/`:data`, but we want to
  # pin the *request* shape here — the parsing contract already has
  # coverage in `client_test.rb` for the HttpError branch.
  class RecordingClient
    attr_reader :calls

    def initialize
      @calls = []
    end

    def respond_with(payload)
      @payload = payload
      self
    end

    def get(_path, options = {})
      @calls << [ :get, options ]
      @payload
    end

    def post(_path, options = {})
      @calls << [ :post, options ]
      @payload
    end
  end

  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
    @previous_cache = Rails.cache
    Rails.cache = @cache

    @recording = RecordingClient.new
    @api = Mixpay::API.new
    # Capture the recording client in a local — the singleton method's
    # block runs in the context of @api, so `@recording` would resolve to
    # `@api.@recording` (nil) rather than the test instance's instance
    # variable. The pre_orders_controller_test uses the same pattern
    # inline; doing it here in setup means every test method needs the
    # closure to already be wired up.
    recording = @recording
    @api.define_singleton_method(:client) { recording }
  end

  teardown do
    Rails.cache = @previous_cache
  end

  # --- endpoint routing ---

  test "settlement_assets GETs /v1/setting/settlement_assets with no params" do
    payload = [ { "assetId" => "abc" } ]
    @recording.respond_with(payload)

    assert_equal payload, @api.settlement_assets

    assert_equal [ [ :get, {} ] ], @recording.calls
  end

  test "quote_assets GETs /v1/setting/quote_assets with no params" do
    payload = [ { "assetId" => "btc" }, { "assetId" => "eth" } ]
    @recording.respond_with(payload)

    assert_equal payload, @api.quote_assets

    assert_equal [ [ :get, {} ] ], @recording.calls
  end

  test "payments_result GETs /v1/payments_result with traceId as a query param" do
    @recording.respond_with({ "data" => { "status" => "success" } })

    @api.payments_result("trace-123")

    verb, options = @recording.calls.first
    assert_equal :get, verb
    assert_equal({ traceId: "trace-123" }, options[:params])
  end

  test "payments_info GETs /v1/payments_info with traceId and clientId query params" do
    @recording.respond_with({ "data" => {} })

    @api.payments_info("trace-abc", "client-xyz")

    verb, options = @recording.calls.first
    assert_equal :get, verb
    assert_equal({ traceId: "trace-abc", clientId: "client-xyz" }, options[:params])
  end

  test "multisig POSTs receivers and threshold as a JSON body" do
    @recording.respond_with({ "data" => { "code" => "ok" } })

    @api.multisig([ "u1", "u2" ], 2)

    verb, options = @recording.calls.first
    assert_equal :post, verb
    assert_equal({ receivers: [ "u1", "u2" ], threshold: 2 }, options[:json])
  end

  # --- cached lookups: quote_assets_cached ---

  test "quote_assets_cached fetches from the client on cache miss" do
    payload = [ { "assetId" => "btc" } ]
    @recording.respond_with(payload)

    assert_equal payload, @api.quote_assets_cached
    assert_equal 1, @recording.calls.size
  end

  test "quote_assets_cached returns the cached payload on subsequent calls" do
    payload = [ { "assetId" => "eth" } ]
    @recording.respond_with(payload)

    first = @api.quote_assets_cached
    second = @api.quote_assets_cached

    assert_equal first, second
    assert_equal 1, @recording.calls.size, "second call should hit the cache"
  end

  test "quote_assets_cached memoizes under the mixpay_quote_assets key" do
    @recording.respond_with([ { "assetId" => "btc" } ])

    @api.quote_assets_cached

    assert_equal [ { "assetId" => "btc" } ], @cache.read("mixpay_quote_assets")
  end

  # --- cached lookups: quote_asset_ids ---

  test "quote_asset_ids extracts assetId strings from the cached quote_assets payload" do
    @recording.respond_with([
      { "assetId" => "btc" },
      { "assetId" => "eth" },
      { "assetId" => "usdt" }
    ])

    assert_equal [ "btc", "eth", "usdt" ], @api.quote_asset_ids
  end

  test "quote_asset_ids hits the cache on subsequent calls without re-fetching" do
    @recording.respond_with([ { "assetId" => "btc" } ])

    @api.quote_asset_ids
    @api.quote_asset_ids

    # quote_asset_ids reads through quote_assets_cached, so the underlying
    # client should only have been invoked once across two reads.
    assert_equal 1, @recording.calls.size
  end

  test "quote_asset_ids memoizes under the mixpay_quote_asset_ids key" do
    @recording.respond_with([ { "assetId" => "btc" }, { "assetId" => "eth" } ])

    @api.quote_asset_ids

    assert_equal [ "btc", "eth" ], @cache.read("mixpay_quote_asset_ids")
  end

  # --- cached lookups: settlement_asset_ids ---

  test "settlement_asset_ids extracts assetId strings from the cached settlement_assets payload" do
    @recording.respond_with([
      { "assetId" => "usdt-erc20" },
      { "assetId" => "usdt-trc20" }
    ])

    assert_equal [ "usdt-erc20", "usdt-trc20" ], @api.settlement_asset_ids
  end

  test "settlement_asset_ids hits the cache on subsequent calls without re-fetching" do
    @recording.respond_with([ { "assetId" => "usdt-erc20" } ])

    @api.settlement_asset_ids
    @api.settlement_asset_ids

    assert_equal 1, @recording.calls.size
  end

  test "settlement_asset_ids memoizes under the mixpay_settlement_asset_ids key" do
    @recording.respond_with([ { "assetId" => "usdt-erc20" } ])

    @api.settlement_asset_ids

    assert_equal [ "usdt-erc20" ], @cache.read("mixpay_settlement_asset_ids")
  end

  # --- cache TTL ---

  test "quote_assets_cached / quote_asset_ids / settlement_asset_ids all use a 10 minute TTL" do
    @recording.respond_with([ { "assetId" => "btc" } ])

    @api.quote_assets_cached
    @api.quote_asset_ids
    @api.settlement_asset_ids

    # Each call sites `Rails.cache.fetch(key, expires_in: 10.minutes)`.
    # `Entry#expires_at` returns the absolute timestamp at which the
    # entry will expire; the remaining TTL (expires_at − now) should be
    # ~600 seconds for each of the three memoized keys.
    ten_minutes = 10 * 60

    %w[mixpay_quote_assets mixpay_quote_asset_ids mixpay_settlement_asset_ids].each do |key|
      entry = @cache.instance_variable_get(:@data)[key]
      assert_not_nil entry, "expected #{key} to be cached"
      remaining = entry.expires_at - Time.now.to_f
      assert_in_delta ten_minutes.to_f, remaining, 60.0,
        "expected #{key} TTL to be ~10 minutes, got #{remaining} seconds remaining"
      assert_not entry.expired?, "expected #{key} to not be expired immediately after write"
    end
  end
end
