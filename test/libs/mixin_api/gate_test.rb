# frozen_string_literal: true

require "test_helper"

class MixinApi::GateTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    Rails.cache.clear
    @scope = :quill_bot
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "enabled? returns true by default" do
    assert MixinApi::Gate.enabled?
  end

  test "acquire and release_success record last request time" do
    travel_to Time.zone.parse("2026-07-05 12:00:00") do
      MixinApi::Gate.acquire(@scope)
      MixinApi::Gate.release_success(@scope)

      last_at = Rails.cache.read("mixin_api_gate:quill_bot:last_request_at")
      assert_equal Time.current.iso8601(6), last_at
    end
  end

  test "proactive spacing waits for min_interval between requests" do
    MixinApi::Gate.release_success(@scope)

    elapsed = Benchmark.realtime { MixinApi::Gate.acquire(@scope) }

    assert_operator elapsed, :>=, 0.1
  end

  test "record_throttle honors retry_after from RateLimitError" do
    error = rate_limit_error(retry_after: 2)

    travel_to Time.zone.parse("2026-07-05 12:00:00") do
      delay = MixinApi::Gate.record_throttle(@scope, error)

      assert_in_delta 2.0, delay, 0.001
      until_time = Rails.cache.read("mixin_api_gate:quill_bot:backoff_until")
      assert_equal (Time.current + 2).iso8601(6), until_time
    end
  end

  test "record_throttle applies exponential backoff capped at max_seconds" do
    error = rate_limit_error

    delay1 = MixinApi::Gate.record_throttle(@scope, error)
    delay2 = MixinApi::Gate.record_throttle(@scope, error)

    assert_in_delta 1.0, delay1, 0.001
    assert_in_delta 2.0, delay2, 0.001
  end

  test "scopes are isolated" do
    error = rate_limit_error

    MixinApi::Gate.record_throttle(:quill_bot, error)

    assert MixinApi::Gate.backoff_remaining(:quill_bot).positive?
    assert_in_delta 0.0, MixinApi::Gate.backoff_remaining(:revenue_bot), 0.001
    assert_in_delta 0.0, MixinApi::Gate.backoff_remaining("user:test-uuid"), 0.001
  end

  test "user scope uses user min_interval config" do
    MixinApi::Gate.release_success("user:abc")

    elapsed = Benchmark.realtime { MixinApi::Gate.acquire("user:abc") }

    assert_operator elapsed, :>=, 0.24
  end

  test "record_throttle logs structured warn line" do
    error = rate_limit_error(retry_after: 3)
    lines = capture_log do
      MixinApi::Gate.record_throttle(@scope, error)
    end

    assert_match(/\[MixinApi::Gate\] scope=quill_bot throttle verb=GET path=\/safe\/snapshots backoff=3\.0s/, lines)
  end

  test "record_throttle rejects non-throttle errors" do
    assert_raises(ArgumentError) do
      MixinApi::Gate.record_throttle(@scope, MixinBot::NotFoundError.new(code: 404))
    end
  end

  private

  def rate_limit_error(retry_after: nil)
    MixinBot::RateLimitError.new(
      code: 429,
      description: "Too Many Requests",
      verb: "GET",
      path: "/safe/snapshots?limit=500",
      retry_after: retry_after
    )
  end

  def capture_log
    lines = +""
    original = Rails.logger
    logger = ActiveSupport::Logger.new(StringIO.new)
    logger.formatter = proc { |_, _, _, msg| lines << "#{msg}\n" }
    Rails.logger = logger
    yield
    lines
  ensure
    Rails.logger = original
  end
end
