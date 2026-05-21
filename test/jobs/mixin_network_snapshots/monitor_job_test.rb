# frozen_string_literal: true

require "test_helper"

class MixinNetworkSnapshots::MonitorJobTest < JobTestCase
  test "perform completes when no delayed snapshots exist" do
    assert_nothing_raised { MixinNetworkSnapshots::MonitorJob.perform_now }
  end

  test "perform processes delayed unprocessed snapshots" do
    snapshot = Object.new
    processed = false
    snapshot.define_singleton_method(:process!) { processed = true }

    delayed = Object.new
    delayed.define_singleton_method(:count) { 1 }
    delayed.define_singleton_method(:map) { |&block| [ snapshot ].map(&block) }

    unprocessed = Object.new
    unprocessed.define_singleton_method(:where) { |*_args| delayed }

    notifier = Object.new
    notifier.define_singleton_method(:text) { |_message| true }

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { unprocessed }) do
      stub_class_method(AdminNotificationService, :new, -> { notifier }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    assert processed
  end
end
