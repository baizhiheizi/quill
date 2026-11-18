# frozen_string_literal: true

require "test_helper"

class RevenueBotTest < ActiveSupport::TestCase
  # Unlike QuillBot (which raises ClientUnavailableError), RevenueBot.api is
  # nil when its credentials are missing — delivery falls back to QuillBot.
  test "api returns nil when the client fails to build" do
    original_api = RevenueBot.method(:api)
    RevenueBot.instance_variable_set(:@api, nil)
    original_build_api = RevenueBot.method(:build_api)
    builds = 0
    RevenueBot.define_singleton_method(:build_api) do
      builds += 1
      raise StandardError, "boom"
    end

    assert_nil RevenueBot.api
    assert_nil RevenueBot.api
    # Each call must re-attempt the build: a failed build is never cached.
    assert_equal 2, builds
  ensure
    RevenueBot.define_singleton_method(:api, original_api)
    RevenueBot.define_singleton_method(:build_api, original_build_api)
    RevenueBot.private_class_method(:build_api)
    RevenueBot.instance_variable_set(:@api, nil)
  end

  test "api memoizes the built client" do
    original_api = RevenueBot.method(:api)
    RevenueBot.instance_variable_set(:@api, nil)
    original_build_api = RevenueBot.method(:build_api)
    original_wrap = MixinApi.method(:wrap)
    fake_api = Object.new
    builds = 0
    wraps = []
    RevenueBot.define_singleton_method(:build_api) do
      builds += 1
      fake_api
    end
    MixinApi.define_singleton_method(:wrap) do |api, **kwargs|
      wraps << kwargs
      api
    end

    assert_same fake_api, RevenueBot.api
    assert_same fake_api, RevenueBot.api
    assert_equal 1, builds
    # The gate budgets per scope (specs/007-mixin-api-rate-gate §4): RevenueBot
    # traffic must be wrapped with its own scope, not QuillBot's.
    assert_equal [ { scope: :revenue_bot, mode: :background } ], wraps
  ensure
    RevenueBot.define_singleton_method(:api, original_api)
    RevenueBot.define_singleton_method(:build_api, original_build_api)
    RevenueBot.private_class_method(:build_api)
    RevenueBot.instance_variable_set(:@api, nil)
    MixinApi.define_singleton_method(:wrap, original_wrap)
  end
end
