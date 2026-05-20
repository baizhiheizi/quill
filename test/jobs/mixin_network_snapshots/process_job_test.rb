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

    MixinNetworkSnapshot.define_singleton_method(:find_by) { |id:| snapshot if id == 1 }
    MixinNetworkSnapshots::ProcessJob.perform_now(1)

    assert called
  ensure
    MixinNetworkSnapshot.singleton_class.remove_method(:find_by)
  end
end
