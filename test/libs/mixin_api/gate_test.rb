# frozen_string_literal: true

require "test_helper"

class MixinApi::GateTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    Rails.cache.clear
    @scope = :quill_bot
    @original_jitter = Settings.mixin_api_gate.backoff.jitter_ratio
    @original_cool_down_after = Settings.mixin_api_gate.backoff.cool_down_after_attempts
    Settings.mixin_api_gate.backoff.jitter_ratio = 0
  end

  teardown do
    Settings.mixin_api_gate.backoff.jitter_ratio = @original_jitter
    Settings.mixin_api_gate.backoff.cool_down_after_attempts = @original_cool_down_after
    Rails.cache = @original_cache
  end

  test "enabled? returns true by default" do
    assert MixinApi::Gate.enabled?
  end

  test "throttled? is true while backoff_until is in the future" do
    MixinApi::Gate.record_throttle(@scope, rate_limit_error(retry_after: 5))

    assert MixinApi::Gate.throttled?(@scope)
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

    assert_operator elapsed, :>=, 0.4
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

  test "record_throttle applies jitter within configured ratio" do
    Settings.mixin_api_gate.backoff.jitter_ratio = 0.25
    Settings.mixin_api_gate.backoff.cool_down_after_attempts = 0
    error = rate_limit_error(retry_after: 10)

    delays = 20.times.map do
      Rails.cache.clear
      MixinApi::Gate.record_throttle(@scope, error)
    end

    delays.each do |delay|
      assert_operator delay, :>=, 7.5
      assert_operator delay, :<=, 12.5
    end
    assert delays.uniq.length > 1
  end

  test "record_throttle applies cool-down after consecutive attempts" do
    Settings.mixin_api_gate.backoff.cool_down_after_attempts = 3
    error = rate_limit_error(retry_after: 1)

    2.times { MixinApi::Gate.record_throttle(@scope, error) }
    delay = MixinApi::Gate.record_throttle(@scope, error)

    assert_in_delta 300.0, delay, 0.001
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
    assert_match(/attempt=1/, lines)
  end

  test "record_throttle rejects non-throttle errors" do
    assert_raises(ArgumentError) do
      MixinApi::Gate.record_throttle(@scope, MixinBot::NotFoundError.new(code: 404))
    end
  end

  test "record_retryable applies exponential backoff" do
    error = Faraday::TimeoutError.new("Net::ReadTimeout")

    delay1 = MixinApi::Gate.record_retryable(@scope, error)
    delay2 = MixinApi::Gate.record_retryable(@scope, error)

    assert_in_delta 1.0, delay1, 0.001
    assert_in_delta 2.0, delay2, 0.001
  end

  test "record_throttle uses exponential backoff when retry_after is zero" do
    error = rate_limit_error(retry_after: 0)

    delay = MixinApi::Gate.record_throttle(@scope, error)

    assert_in_delta 1.0, delay, 0.001
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
