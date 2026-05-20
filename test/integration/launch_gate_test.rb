# frozen_string_literal: true

require "test_helper"

class LaunchGateTest < ActiveSupport::TestCase
  setup do
    @controller = ApplicationController.new
    @original_launch_time = Settings.launch_time
    @original_whitelist = Settings.whitelist
  end

  teardown do
    Settings.launch_time = @original_launch_time
    Settings.whitelist = @original_whitelist
  end

  test "launched? is true when launch_time is blank" do
    Settings.launch_time = nil

    assert @controller.send(:launched?)
  end

  test "launched? is false before launch_time" do
    Settings.launch_time = 1.day.from_now.iso8601
    @controller.define_singleton_method(:current_user) { nil }
    @controller.define_singleton_method(:current_session) { nil }

    assert_not @controller.send(:launched?)
  end

  test "launched? allows accessable users before launch" do
    user = users(:author)
    Settings.launch_time = 1.day.from_now.iso8601
    Settings.whitelist = Config::Options.new(enable: true, mixin_id: [ user.mixin_uuid ])

    @controller.define_singleton_method(:current_user) { user }
    @controller.define_singleton_method(:current_session) { nil }

    assert @controller.send(:launched?)
  end
end
