# frozen_string_literal: true

require "test_helper"

class MixinNetworkSnapshots::MonitorJobTest < JobTestCase
  include ActiveSupport::Testing::ErrorReporterAssertions

  test "perform completes when no delayed snapshots exist" do
    relation = delayed_relation(none: true)

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { relation }) do
      assert_nothing_raised { MixinNetworkSnapshots::MonitorJob.perform_now }
    end
  end

  test "perform processes delayed unprocessed snapshots and alerts with the delayed count" do
    snapshot = Object.new
    snapshot.define_singleton_method(:id) { 42 }
    processed = false
    snapshot.define_singleton_method(:process!) { processed = true }

    relation = delayed_relation(count: 1, members: [ snapshot ])

    alert_message = nil
    notifier = Object.new
    notifier.define_singleton_method(:text) { |message| alert_message = message }

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { relation }) do
      stub_class_method(AdminNotificationService, :new, -> { notifier }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    assert processed
    assert_match(/There are 1 unprocessed snapshots/, alert_message)
    refute_match(/failed to process/, alert_message)
  end

  test "perform does not notify admin when no delayed snapshots exist" do
    # `AdminNotificationService#text` is the only call path the job has to
    # raise an admin alert. When nothing is delayed, the job must NOT
    # instantiate an admin notifier at all.
    relation = delayed_relation(none: true)
    notifier_instantiated = false

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { relation }) do
      stub_class_method(AdminNotificationService, :new, -> {
        notifier_instantiated = true
        Object.new
      }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    refute notifier_instantiated, "expected AdminNotificationService.new NOT to be called when nothing is delayed"
  end

  test "perform processes every delayed snapshot, not just the first" do
    # A regression to `first` or `take(1)` would still pass the single-snapshot
    # happy path. Yield three members from the relation and confirm every
    # snapshot had `process!` called on it.
    processed_ids = []
    members = Array.new(3) do |i|
      s = Object.new
      s.define_singleton_method(:process!) { processed_ids << i }
      s
    end

    relation = delayed_relation(count: 3, members: members)
    notifier = Object.new
    notifier.define_singleton_method(:text) { |_message| true }

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { relation }) do
      stub_class_method(AdminNotificationService, :new, -> { notifier }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    assert_equal [ 0, 1, 2 ], processed_ids
  end

  test "perform alerts the admin even when a snapshot fails to process" do
    # One poisoned snapshot (e.g. `Payment.find_or_create_by!` raising inside
    # `process!`) must not abort the sweep before the admin delay-alert
    # fires — the alert is the job's entire purpose, and it previously never
    # fired in exactly the stuck state it exists to report.
    healthy_processed = false
    healthy = Object.new
    healthy.define_singleton_method(:id) { 43 }
    healthy.define_singleton_method(:process!) { healthy_processed = true }

    poisoned = Object.new
    poisoned.define_singleton_method(:id) { 42 }
    # `ActiveRecord::RecordInvalid` carries the offending record — passing a
    # bare String raises `NoMethodError` from the constructor instead.
    invalid_record = MixinNetworkSnapshot.new
    invalid_record.errors.add(:base, "is not a valid snapshot")
    poisoned.define_singleton_method(:process!) { raise ActiveRecord::RecordInvalid.new(invalid_record) }

    relation = delayed_relation(count: 2, members: [ poisoned, healthy ])

    alert_message = nil
    notifier = Object.new
    notifier.define_singleton_method(:text) { |message| alert_message = message }

    report = assert_error_reported(ActiveRecord::RecordInvalid) do
      stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { relation }) do
        stub_class_method(AdminNotificationService, :new, -> { notifier }) do
          MixinNetworkSnapshots::MonitorJob.perform_now
        end
      end
    end

    assert healthy_processed
    assert_match(/There are 2 unprocessed snapshots/, alert_message)
    # The alert must distinguish "the sweep recovered every row" from "a row is
    # still broken" — the delayed count alone reads the same in both cases.
    assert_match(/1 failed to process/, alert_message)

    # A poisoned row is only visible in error tracking if the per-row rescue
    # reports it, matching `Orders::BatchDistributeJob`.
    assert_predicate report, :handled?
    assert_equal :warning, report.severity
    assert_equal "MixinNetworkSnapshots::MonitorJob", report.context[:job]
    assert_equal 42, report.context[:snapshot_id]
  end

  test "the alert reports the delayed count captured before processing" do
    # `unprocessed.where(...)` re-queries `processed_at IS NULL` on every
    # `count`, so reading the count again after the loop reports however many
    # rows are STILL stuck — 0 when this run processed them all. The alert
    # must carry the pre-processing count.
    processed = false
    member = Object.new
    member.define_singleton_method(:process!) { processed = true }

    relation = Object.new
    relation.define_singleton_method(:where) { |*_args| relation }
    relation.define_singleton_method(:none?) { false }
    relation.define_singleton_method(:count) { processed ? 0 : 2 }
    relation.define_singleton_method(:find_each) { |&block| [ member ].each(&block) }

    alert_message = nil
    notifier = Object.new
    notifier.define_singleton_method(:text) { |message| alert_message = message }

    stub_class_method(MixinNetworkSnapshot, :unprocessed, -> { relation }) do
      stub_class_method(AdminNotificationService, :new, -> { notifier }) do
        MixinNetworkSnapshots::MonitorJob.perform_now
      end
    end

    assert processed
    assert_match(/There are 2 unprocessed snapshots/, alert_message)
  end

  test "perform is queued as :low" do
    assert_equal "low", MixinNetworkSnapshots::MonitorJob.new.queue_name
  end

  test "perform sweeps a real delayed snapshot row through a real relation" do
    # The stub relation above replaces the whole `ActiveRecord::Relation`, so
    # it can never catch a `find_each` that breaks on a real relation (loaded
    # relation, implicit ordering, cursor validation). Run the sweep against a
    # real row so the production path is actually covered.
    #
    # This test deliberately does NOT stub `MixinNetworkSnapshot.unprocessed`:
    # the real scope has to resolve the delayed row on its own.
    MixinNetworkSnapshot.unprocessed.delete_all

    snapshot = MixinNetworkSnapshot.create!(
      amount: 1,
      asset_id: SecureRandom.uuid,
      user_id: SecureRandom.uuid,
      snapshot_id: SecureRandom.uuid,
      trace_id: SecureRandom.uuid,
      transferred_at: 2.minutes.ago,
      created_at: 2.minutes.ago
    )

    alert_message = nil
    notifier = Object.new
    notifier.define_singleton_method(:text) { |message| alert_message = message }

    stub_class_method(AdminNotificationService, :new, -> { notifier }) do
      MixinNetworkSnapshots::MonitorJob.perform_now
    end

    assert snapshot.reload.processed_at.present?, "expected the delayed snapshot to be marked processed"
    assert_match(/There are 1 unprocessed snapshots/, alert_message)
  end

  private

  # Stubs the `unprocessed` scope: the job chains `.where(created_at: ...)`
  # onto its return, so the scope object answers `where` with the delayed
  # relation that carries `none?`/`count`/`find_each`.
  def delayed_relation(none: false, count: 0, members: [])
    relation = Object.new
    relation.define_singleton_method(:none?) { none }
    relation.define_singleton_method(:count) { count }
    relation.define_singleton_method(:find_each) { |&block| members.each(&block) }

    scope = Object.new
    scope.define_singleton_method(:where) { |*_args| relation }
    scope
  end
end
