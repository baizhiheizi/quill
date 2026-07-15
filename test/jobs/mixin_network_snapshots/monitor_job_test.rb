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

  test "perform does not notify admin when no delayed snapshots exist" do
    # `AdminNotificationService#text` is the only call path the job has to
    # raise an admin alert. When `unprocessed.where(...).count` is zero, the
    # job must NOT instantiate an admin notifier at all (existing behavior
    # verified by the no-op happy path above; this test pins the no-notify
    # side of that contract).
    notifier_instantiated = false

    delayed = Object.new
    delayed.define_singleton_method(:count) { 0 }

    unprocessed = Object.new
    unprocessed.define_singleton_method(:where) { |*_args| delayed }

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { unprocessed }) do
      stub_class_method(AdminNotificationService, :new, -> {
        notifier_instantiated = true
        Object.new.tap { |o| o.define_singleton_method(:text) { |_| true } }
      }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    refute notifier_instantiated, "expected AdminNotificationService.new NOT to be called when count is zero"
  end

  test "perform processes every delayed snapshot, not just the first" do
    # A regression to `first` or `take(1)` would still pass the single-snapshot
    # happy path. Stub `.map` to invoke the block on all members and confirm
    # every snapshot had `process!` called on it.
    snapshots = Array.new(3) do
      s = Object.new
      s.define_singleton_method(:process!) { nil }
      s
    end

    processed_ids = []
    snapshots.each_with_index { |s, i| s.define_singleton_method(:process!) { processed_ids << i } }

    delayed = Object.new
    delayed.define_singleton_method(:count) { snapshots.size }
    delayed.define_singleton_method(:map) { |&block| snapshots.map(&block) }

    unprocessed = Object.new
    unprocessed.define_singleton_method(:where) { |*_args| delayed }

    notifier = Object.new
    notifier.define_singleton_method(:text) { |_message| true }

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { unprocessed }) do
      stub_class_method(AdminNotificationService, :new, -> { notifier }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    assert_equal [ 0, 1, 2 ], processed_ids
  end

  test "perform is queued as :low" do
    assert_equal "low", MixinNetworkSnapshots::MonitorJob.new.queue_name
  end
end
