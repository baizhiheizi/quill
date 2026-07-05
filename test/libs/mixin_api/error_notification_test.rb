# frozen_string_literal: true

require "test_helper"

class MixinApi::ErrorNotificationTest < ActiveSupport::TestCase
  test "skip? is true for RateLimitError" do
    error = MixinBot::RateLimitError.new(
      code: 429,
      description: "Too Many Requests",
      verb: "GET",
      path: "/safe/snapshots"
    )

    assert MixinApi::ErrorNotification.skip?(error)
  end

  test "skip? is true for retryable server errors" do
    error = MixinBot::ServerError.new(code: 500, description: "Internal Server Error", verb: "GET", path: "/me")

    assert MixinApi::ErrorNotification.skip?(error)
  end

  test "skip? is true for Faraday timeouts" do
    assert MixinApi::ErrorNotification.skip?(Faraday::TimeoutError.new("Net::ReadTimeout"))
  end

  test "skip? is false for unrelated application errors" do
    assert_not MixinApi::ErrorNotification.skip?(StandardError.new("database unavailable"))
  end

  test "notify_unless_mixin_api skips Mixin API errors" do
    error = MixinBot::RateLimitError.new(
      code: 429,
      description: "Too Many Requests",
      verb: "GET",
      path: "/safe/snapshots"
    )

    lines = capture_log { MixinApi::ErrorNotification.notify_unless_mixin_api(error, context: "test") }

    assert_match(/Skipped Mixin bot exception notification/, lines)
  end

  test "notify_unless_mixin_api delegates other errors to ExceptionNotifier" do
    error = StandardError.new("unexpected")
    notified = false
    original = ExceptionNotifier.method(:notify_exception)
    ExceptionNotifier.define_singleton_method(:notify_exception) do |exception, _options = {}|
      notified = (exception == error)
    end

    MixinApi::ErrorNotification.notify_unless_mixin_api(error)

    assert notified
  ensure
    ExceptionNotifier.define_singleton_method(:notify_exception, original)
  end

  private

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
