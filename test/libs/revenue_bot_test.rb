# frozen_string_literal: true

require "test_helper"

class RevenueBotTest < ActiveSupport::TestCase
  # Unlike QuillBot (which raises ClientUnavailableError), RevenueBot.api is
  # nil when its credentials are missing — delivery falls back to QuillBot.
  test "api returns nil when the client fails to build" do
    original_api = RevenueBot.method(:api)
    RevenueBot.instance_variable_set(:@api, nil)
    original_build_api = RevenueBot.method(:build_api)
    RevenueBot.define_singleton_method(:build_api) { raise StandardError, "boom" }

    assert_nil RevenueBot.api
    assert_nil RevenueBot.api
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
    RevenueBot.define_singleton_method(:build_api) do
      builds += 1
      fake_api
    end
    MixinApi.define_singleton_method(:wrap) { |api, **| api }

    assert_same fake_api, RevenueBot.api
    assert_same fake_api, RevenueBot.api
    assert_equal 1, builds
  ensure
    RevenueBot.define_singleton_method(:api, original_api)
    RevenueBot.define_singleton_method(:build_api, original_build_api)
    RevenueBot.private_class_method(:build_api)
    RevenueBot.instance_variable_set(:@api, nil)
    MixinApi.define_singleton_method(:wrap, original_wrap)
  end
end
