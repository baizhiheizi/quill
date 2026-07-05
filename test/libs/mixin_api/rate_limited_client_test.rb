# frozen_string_literal: true

require "test_helper"

class MixinApi::RateLimitedClientTest < ActiveSupport::TestCase
  FakeEnvelope = Struct.new(:data)

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    Rails.cache.clear
    @scope = :quill_bot
    @inner = Object.new
    @client = MixinApi::RateLimitedClient.new(@inner, scope: @scope, mode: :background)
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "background mode retries after RateLimitError then succeeds" do
    attempts = 0
    @inner.define_singleton_method(:get) do |*_args, **_kwargs|
      attempts += 1
      if attempts == 1
        raise MixinBot::RateLimitError.new(
          code: 429, description: "Too Many Requests", verb: "GET", path: "/safe/snapshots", retry_after: 0
        )
      end

      FakeEnvelope.new("ok")
    end

    result = @client.get("/safe/snapshots", limit: 500)
    assert_equal "ok", result.data
    assert_equal 2, attempts
  end

  test "interactive mode re-raises RateLimitError after max wait" do
    client = MixinApi::RateLimitedClient.new(@inner, scope: @scope, mode: :interactive)
    @inner.define_singleton_method(:get) do |_path, **_kwargs|
      raise MixinBot::RateLimitError.new(
        code: 429, description: "Too Many Requests", verb: "GET", path: "/me", retry_after: 0
      )
    end

    original = Settings.mixin_api_gate.interactive_max_wait_seconds
    Settings.mixin_api_gate.interactive_max_wait_seconds = 0

    assert_raises(MixinBot::RateLimitError) { client.get("/me") }
  ensure
    Settings.mixin_api_gate.interactive_max_wait_seconds = original
  end

  test "NotFoundError passes through without retry" do
    attempts = 0
    @inner.define_singleton_method(:get) do |*_args, **_kwargs|
      attempts += 1
      raise MixinBot::NotFoundError.new(code: 404, description: "Not Found", verb: "GET", path: "/safe/transactions/abc")
    end

    assert_raises(MixinBot::NotFoundError) { @client.get("/safe/transactions/abc") }
    assert_equal 1, attempts
  end

  test "safe_snapshots-style GET retries indefinitely in background mode" do
    attempts = 0
    @inner.define_singleton_method(:get) do |path, **_kwargs|
      attempts += 1
      if attempts <= 2
        raise MixinBot::RateLimitError.new(
          code: 429, description: "Too Many Requests", verb: "GET", path: path, retry_after: 0
        )
      end

      FakeEnvelope.new([ { "snapshot_id" => SecureRandom.uuid } ])
    end

    result = @client.get("/safe/snapshots", limit: 500, order: "ASC")
    assert_equal 1, result.data.length
    assert_equal 3, attempts
  end
end
