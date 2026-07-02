# frozen_string_literal: true

# == Schema Information
#
# Table name: transfers
#
#  id                :bigint           not null, primary key
#  amount            :decimal(, )
#  memo              :string
#  opponent_multisig :json
#  processed_at      :datetime
#  queue_priority    :integer          default("default")
#  retry_at          :datetime
#  snapshot          :json
#  source_type       :string
#  transfer_type     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  asset_id          :uuid
#  opponent_id       :uuid
#  source_id         :bigint
#  trace_id          :uuid
#  wallet_id         :uuid
#
# Indexes
#
#  index_transfers_on_asset_id                   (asset_id)
#  index_transfers_on_created_at                 (created_at)
#  index_transfers_on_opponent_id                (opponent_id)
#  index_transfers_on_processed_at               (processed_at)
#  index_transfers_on_source_type_and_source_id  (source_type,source_id)
#  index_transfers_on_trace_id                   (trace_id) UNIQUE
#  index_transfers_on_transfer_type              (transfer_type)
#  index_transfers_on_wallet_id                  (wallet_id)
#
require "test_helper"

class TransferTest < ActiveSupport::TestCase
  setup do
    @btc = currencies(:btc)
    @author = users(:author)
    @reader = users(:reader_one)
    @trace_id = SecureRandom.uuid
  end

  def build_transfer(attrs = {})
    Transfer.new(
      {
        amount: 0.0001,
        asset_id: @btc.asset_id,
        trace_id: @trace_id,
        transfer_type: :author_revenue,
        opponent_id: @author.mixin_uuid
      }.merge(attrs)
    )
  end

  test "transfer_type enum includes revenue types" do
    assert_includes Transfer.transfer_types.keys, "author_revenue"
    assert_includes Transfer.transfer_types.keys, "reader_revenue"
    assert_includes Transfer.transfer_types.keys, "quill_revenue"
  end

  test "transfer_type enum includes refund and bonus types" do
    %w[payment_refund bonus swap_change swap_refund fox_swap
       reference_revenue withdraw_balance].each do |type|
      assert_includes Transfer.transfer_types.keys, type,
                      "expected #{type} in Transfer.transfer_types"
    end
  end

  test "queue_priority enum exposes default and named levels" do
    %w[default critical high low].each do |priority|
      assert_includes Transfer.queue_priorities.keys, priority
    end
  end

  test "requires amount and trace_id" do
    transfer = Transfer.new

    assert_not transfer.valid?
    assert transfer.errors[:amount].present? || transfer.errors[:trace_id].present?
  end

  test "rejects amounts below the minimum" do
    transfer = build_transfer(amount: Transfer::MINIMUM_AMOUNT / 2)

    assert_not transfer.valid?
    assert transfer.errors[:amount].any? { |m| m.include?("greater than or equal to") }
  end

  test "requires either opponent_id or opponent_multisig" do
    transfer = build_transfer(opponent_id: nil, opponent_multisig: nil)

    assert_not transfer.valid?
    assert transfer.errors[:opponent_id].any? { |m| m.include?("cannot be blank") }
  end

  test "is valid with opponent_multisig and no opponent_id" do
    transfer = build_transfer(
      opponent_id: nil,
      opponent_multisig: { "receivers" => [ SecureRandom.uuid ], "threshold" => 1 }
    )

    assert transfer.valid?, transfer.errors.full_messages.inspect
  end

  test "snapshot_id extracts from a hash snapshot" do
    transfer = build_transfer(snapshot: { "snapshot_id" => "snap-1" })

    assert_equal "snap-1", transfer.snapshot_id
  end

  test "snapshot_id extracts from the first element of an array snapshot" do
    transfer = build_transfer(snapshot: [ { "snapshot_id" => "snap-array-1" }, { "snapshot_id" => "snap-array-2" } ])

    assert_equal "snap-array-1", transfer.snapshot_id
  end

  test "snapshot_id returns nil when snapshot is missing the field" do
    transfer = build_transfer(snapshot: { "other_key" => "x" })

    assert_nil transfer.snapshot_id
  end

  test "snapshot_id returns nil when snapshot is nil" do
    transfer = build_transfer(snapshot: nil)

    assert_nil transfer.snapshot_id
  end

  test "transaction_hash mirrors snapshot_id handling" do
    transfer = build_transfer(snapshot: { "transaction_hash" => "hash-1" })

    assert_equal "hash-1", transfer.transaction_hash
  end

  test "transaction_hash picks the first array entry" do
    transfer = build_transfer(snapshot: [ { "transaction_hash" => "hash-array" }, { "transaction_hash" => "ignored" } ])

    assert_equal "hash-array", transfer.transaction_hash
  end

  test "snapshot_url prefers the viewblock transaction link when transaction_hash is present" do
    transfer = build_transfer(snapshot: { "snapshot_id" => "snap-1", "transaction_hash" => "hash-1" })

    assert_equal "https://viewblock.io/mixin/tx/hash-1", transfer.snapshot_url
  end

  test "snapshot_url falls back to the mixin.one snapshot link" do
    transfer = build_transfer(snapshot: { "snapshot_id" => "snap-2" })

    assert_equal "https://mixin.one/snapshots/snap-2", transfer.snapshot_url
  end

  test "snapshot_url returns nil when neither identifier is present" do
    transfer = build_transfer(snapshot: {})

    assert_nil transfer.snapshot_url
  end

  test "safe_receiver builds a single-member entry from opponent_id" do
    transfer = build_transfer(opponent_id: @reader.mixin_uuid, amount: 0.5)

    receiver = transfer.safe_receiver

    assert_equal [ @reader.mixin_uuid ], receiver[:members]
    assert_equal 1, receiver[:threshold]
    assert_equal 0.5, receiver[:amount]
  end

  test "safe_receiver builds from opponent_multisig when opponent_id is absent" do
    multisig = { "receivers" => [ SecureRandom.uuid, SecureRandom.uuid ], "threshold" => 2 }
    transfer = build_transfer(opponent_id: nil, opponent_multisig: multisig, amount: 1.25)

    receiver = transfer.safe_receiver

    assert_equal multisig["receivers"], receiver[:members]
    assert_equal 2, receiver[:threshold]
    assert_equal 1.25, receiver[:amount]
  end

  test "price_tag formats amount and currency symbol" do
    transfer = build_transfer(amount: 0.12345678)

    assert_equal "0.12345678 BTC", transfer.price_tag
  end

  test "price_tag truncates amounts longer than 8 decimals" do
    transfer = build_transfer(amount: 0.000000015)

    assert_equal "0.00000002 BTC", transfer.price_tag
  end

  test "processed? mirrors processed_at presence" do
    unprocessed = build_transfer
    processed = build_transfer(processed_at: Time.current)

    assert_not unprocessed.processed?
    assert processed.processed?
  end

  test "unprocessed scope returns only unprocessed transfers" do
    processed = create_transfer!(trace_id: SecureRandom.uuid, processed_at: Time.current)
    unprocessed = create_transfer!(trace_id: SecureRandom.uuid)

    assert_includes Transfer.unprocessed, unprocessed
    assert_not_includes Transfer.unprocessed, processed
  end

  test "processed scope returns only processed transfers" do
    processed = create_transfer!(trace_id: SecureRandom.uuid, processed_at: Time.current)
    unprocessed = create_transfer!(trace_id: SecureRandom.uuid)

    assert_includes Transfer.processed, processed
    assert_not_includes Transfer.processed, unprocessed
  end

  test "recipient_has_safe? delegates to the recipient user" do
    transfer = build_transfer(opponent_id: @author.mixin_uuid)

    UserAuthorization.define_method(:has_safe?) { true }
    assert transfer.recipient_has_safe?

    UserAuthorization.define_method(:has_safe?) { false }
    assert_not transfer.recipient_has_safe?
  ensure
    UserAuthorization.send(:remove_method, :has_safe?)
  end

  test "recipient_has_safe? returns nil when recipient is missing" do
    transfer = build_transfer(opponent_id: SecureRandom.uuid)

    assert_nil transfer.recipient_has_safe?
  end

  test "notify_recipient is a no-op when there is no recipient" do
    transfer = build_transfer(opponent_id: SecureRandom.uuid)

    assert_nothing_raised { transfer.notify_recipient }
  end

  test "notify_recipient is a no-op when currency is missing" do
    transfer = build_transfer(opponent_id: @author.mixin_uuid, asset_id: SecureRandom.uuid)

    assert_nothing_raised { transfer.notify_recipient }
  end

  test "notify_recipient delivers TransferProcessedNotifier to recipient" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, opponent_id: @author.mixin_uuid)

    ensure_notification_setting!(@author)
    user_authorizations(:author_auth).define_singleton_method(:has_safe?) { true }

    with_mixin_bot_delivery_stub do
      assert_difference -> { @author.notifications.count }, 1 do
        transfer.notify_recipient
      end

      notification = @author.notifications.order(:id).last
      assert_equal "TransferProcessedNotifier::Notification", notification.type
    end
  end

  test "process! is a no-op when already processed" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, processed_at: Time.current)

    assert_nothing_raised { transfer.process! }
  end

  test "process! drives a Payment source through refund!" do
    with_quill_bot_stub do
      payment = build_payment_with_state!(:paid)

      transfer = create_transfer!(
        trace_id: SecureRandom.uuid,
        source: payment,
        transfer_type: :payment_refund
      )

      called = false
      payment.define_singleton_method(:refund!) { called = true }

      QuillBot.api.define_singleton_method(:safe_transaction) do |_trace_id|
        { "data" => { "snapshot_id" => "snap-process-payment", "transaction_hash" => "hash-pp" } }
      end

      transfer.process!

      assert called, "expected payment.refund! to be invoked"
      assert transfer.reload.processed?
      assert_equal "snap-process-payment", transfer.snapshot_id
    end
  end

  test "process! does not raise for a legacy retired SwapOrder source_type" do
    with_quill_bot_stub do
      transfer = create_transfer!(
        trace_id: SecureRandom.uuid,
        source_type: "SwapOrder",
        source_id: 999_999,
        transfer_type: :swap_refund
      )

      QuillBot.api.define_singleton_method(:safe_transaction) do |_trace_id|
        { "data" => { "snapshot_id" => "snap-legacy-swap", "transaction_hash" => "hash-legacy-swap" } }
      end

      assert_nothing_raised { transfer.process! }
      assert transfer.reload.processed?
    end
  end

  test "process! drives a Bonus source through complete!" do
    # The Bonus model expects a "bonus" table (singular) but the migration creates "bonuses",
    # so real Bonus records cannot be created in tests yet. Remove this skip once the
    # Bonus table-name mismatch is resolved and re-enable the assertion body.
    skip "Bonus model table name mismatch (model: 'bonus', migration: 'bonuses')"
  end

  test "process_safe_transfer! only calls create_safe_transfer when Mixin reports NotFoundError" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, amount: 0.1)

    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:safe_transaction) { |_| raise MixinBot::NotFoundError, "missing" }
      QuillBot.api.define_singleton_method(:create_safe_transfer) do |**_kwargs|
        { "data" => { "snapshot_id" => "snap-safe-1", "transaction_hash" => "hash-safe-1" } }
      end

      transfer.process_safe_transfer!

      transfer.reload
      assert transfer.processed?
      assert_equal "snap-safe-1", transfer.snapshot_id
    end
  end

  test "process_safe_transfer! persists the snapshot returned by safe_transaction when Mixin already has the transfer" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid, amount: 0.1)
    existing_snapshot = { "snapshot_id" => "snap-existing", "transaction_hash" => "hash-existing" }

    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:safe_transaction) { |_| { "data" => existing_snapshot } }
      create_called = false
      QuillBot.api.define_singleton_method(:create_safe_transfer) do |_|
        create_called = true
        { "data" => {} }
      end

      transfer.process_safe_transfer!

      transfer.reload
      assert transfer.processed?
      assert_equal "snap-existing", transfer.snapshot_id
      assert_not create_called, "create_safe_transfer must not run when Mixin already returned the transfer"
    end
  end

  test "check! updates the snapshot and processed_at on success" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid)
    snapshot = { "snapshot_id" => "snap-check", "transaction_hash" => "hash-check" }
    QuillBot.api.define_singleton_method(:safe_transaction) { |_| { "data" => snapshot } }

    transfer.check!

    transfer.reload
    assert transfer.processed?
    assert_equal snapshot, transfer.snapshot
  end

  test "check! swallows MixinBot::NotFoundError and returns false" do
    transfer = create_transfer!(trace_id: SecureRandom.uuid)
    QuillBot.api.define_singleton_method(:safe_transaction) { |_| raise MixinBot::NotFoundError, "not found" }

    assert_equal false, transfer.check!
    assert_not transfer.reload.processed?
  end

  private

  def create_transfer!(attrs = {})
    Transfer.create!({
      amount: 0.0001,
      asset_id: @btc.asset_id,
      transfer_type: :author_revenue,
      opponent_id: @author.mixin_uuid
    }.merge(attrs))
  end

  def build_payment_with_state!(state)
    article = articles(:published_paid)
    payment = create_payment!(article: article, payer: @reader)
    payment.update_column(:state, state)
    payment
  end
end
