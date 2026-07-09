# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_snapshots
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(, )
#  data           :string
#  processed_at   :datetime
#  transferred_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  asset_id       :uuid
#  opponent_id    :uuid
#  snapshot_id    :uuid
#  trace_id       :uuid
#  user_id        :uuid
#
# Indexes
#
#  index_mixin_network_snapshots_on_created_at    (created_at)
#  index_mixin_network_snapshots_on_processed_at  (processed_at)
#  index_mixin_network_snapshots_on_snapshot_id   (snapshot_id) UNIQUE
#  index_mixin_network_snapshots_on_trace_id      (trace_id)
#  index_mixin_network_snapshots_on_user_id       (user_id)
#

require "test_helper"

class MixinNetworkSnapshotTest < ActiveSupport::TestCase
  def build_snapshot(memo_payload:, amount: 1)
    MixinNetworkSnapshot.new(
      amount: amount,
      asset_id: SecureRandom.uuid,
      data: Base64.encode64(memo_payload.to_json),
      transferred_at: Time.current,
      user_id: SecureRandom.uuid,
      snapshot_id: SecureRandom.uuid,
      trace_id: SecureRandom.uuid
    )
  end

  test "legacy_4swap_snapshot? recognizes retired 4swap memo protocol" do
    trade = build_snapshot(memo_payload: { "s" => "4swapTrade", "t" => SecureRandom.uuid })
    refund = build_snapshot(memo_payload: { "s" => "4swapRefund", "t" => SecureRandom.uuid })
    payment = build_snapshot(memo_payload: { "t" => "BUY", "a" => SecureRandom.uuid })

    assert trade.legacy_4swap_snapshot?
    assert refund.legacy_4swap_snapshot?
    refute payment.legacy_4swap_snapshot?
  end

  test "process! does not silently create a payment for a legacy 4swap snapshot" do
    snapshot = build_snapshot(memo_payload: { "s" => "4swapTrade", "t" => SecureRandom.uuid })
    snapshot.save!

    assert_no_difference "Payment.count" do
      snapshot.process!
    end

    assert snapshot.reload.processed?
  end

  test "poll_retry_delay increases with attempt count and caps at 60 seconds" do
    assert_in_delta 5.0, MixinNetworkSnapshot.poll_retry_delay(0), 0.001
    assert_in_delta 10.0, MixinNetworkSnapshot.poll_retry_delay(1), 0.001
    assert_in_delta 60.0, MixinNetworkSnapshot.poll_retry_delay(10), 0.001
  end

  test "poll_sleep_duration uses idle interval for partial pages" do
    assert_in_delta MixinNetworkSnapshot::POLLING_IDLE_INTERVAL,
                    MixinNetworkSnapshot.poll_sleep_duration(10),
                    0.001
  end

  test "poll_sleep_duration uses catch-up interval for full pages" do
    assert_in_delta MixinNetworkSnapshot::POLLING_INTERVAL,
                    MixinNetworkSnapshot.poll_sleep_duration(MixinNetworkSnapshot::POLLING_LIMIT),
                    0.001
  end

  test "poll_sleep_duration respects gate backoff remaining" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    Rails.cache.clear
    original_jitter = Settings.mixin_api_gate.backoff.jitter_ratio
    Settings.mixin_api_gate.backoff.jitter_ratio = 0

    MixinApi::Gate.record_throttle(
      :quill_bot,
      MixinBot::RateLimitError.new(
        code: 429,
        description: "Too Many Requests",
        verb: "GET",
        path: "/safe/snapshots",
        retry_after: 12
      )
    )

    assert_operator MixinNetworkSnapshot.poll_sleep_duration(10), :>=, 11.0
  ensure
    Settings.mixin_api_gate.backoff.jitter_ratio = original_jitter
    Rails.cache = original_cache
  end
end
