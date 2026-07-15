# frozen_string_literal: true

require "test_helper"

class MixinNetworkSnapshots::ProcessJobTest < JobTestCase
  test "perform calls process! on snapshot" do
    snapshot = MixinNetworkSnapshot.new(
      amount: 1.0,
      asset_id: Currency::BTC_ASSET_ID,
      user_id: mixin_network_users(:quill_wallet).uuid,
      snapshot_id: SecureRandom.uuid,
      trace_id: SecureRandom.uuid,
      transferred_at: Time.current
    )
    called = false
    snapshot.define_singleton_method(:process!) { called = true }

    stub_class_method(MixinNetworkSnapshot, :find_by, ->(**kwargs) { kwargs[:id] == 1 ? snapshot : nil }) do
      MixinNetworkSnapshots::ProcessJob.perform_now(1)
    end

    assert called
  end

  test "perform no-ops for missing snapshot" do
    stub_class_method(MixinNetworkSnapshot, :find_by, ->(**) { nil }) do
      assert_nothing_raised { MixinNetworkSnapshots::ProcessJob.perform_now(SecureRandom.uuid) }
    end
  end

  test "perform uses safe-navigation so a nil snapshot does not raise" do
    # `MixinNetworkSnapshot.find_by(id:)&.process!` — the `&.` is what lets the
    # job no-op on a missing record. Pin that contract so a future refactor
    # to `find_by(id:).process!` (no `&.`) gets caught immediately.
    stub_class_method(MixinNetworkSnapshot, :find_by, ->(**) { nil }) do
      assert_nothing_raised { MixinNetworkSnapshots::ProcessJob.perform_now(-1) }
    end
  end

  test "perform is queued as :critical" do
    assert_equal "critical", MixinNetworkSnapshots::ProcessJob.new.queue_name
  end
end
