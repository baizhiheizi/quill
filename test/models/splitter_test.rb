# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_users
# Database name: primary
#
#  id            :bigint           not null, primary key
#  encrypted_pin :string
#  name          :string
#  owner_type    :string
#  pin           :string
#  pin_token     :string
#  private_key   :string
#  raw           :json
#  type          :string
#  uuid          :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :bigint
#  session_id    :uuid
#
# Indexes
#
#  index_mixin_network_users_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_mixin_network_users_on_uuid                     (uuid) UNIQUE
#

require "test_helper"

# Covers the `Splitter` model — an STI subclass of `MixinNetworkUser` that
# holds the per-asset "sweep" wallet. The single business-logic method,
# `collect_assets`, walks the wallet's on-chain balances and creates a
# `Transfer` per non-zero balance that has no in-flight outgoing transfer.
#
# `pin` is `encrypts`-protected and ActiveRecord encryption is not configured
# in the test credentials (no `active_record_encryption.primary_key`), so the
# tests never exercise the decrypting accessor. `collect_assets` only reads
# `transfers` and `mixin_api`, both of which we stub per-instance, so this
# hazard does not reach the test surface.
class SplitterTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # STI
  # ---------------------------------------------------------------------------

  test "is an STI subclass of MixinNetworkUser with type='Splitter'" do
    splitter = Splitter.new

    assert_kind_of MixinNetworkUser, splitter
    assert_equal "Splitter", splitter.type
    assert_includes splitter.class.ancestors, MixinNetworkUser
    assert_includes splitter.class.ancestors, AdvisoryLockable
  end

  test "type is filterable through MixinNetworkUser.where(type: 'Splitter')" do
    splitter = build_splitter(overrides: { name: "Filter Splitter #{SecureRandom.hex(4)}" })
    splitter.save(validate: false)

    assert_includes MixinNetworkUser.where(type: "Splitter").pluck(:uuid), splitter.uuid
  end

  # ---------------------------------------------------------------------------
  # collect_assets
  # ---------------------------------------------------------------------------

  test "collect_assets wraps the body in with_advisory_lock keyed to 'splitter:<id>:collect'" do
    splitter = persisted_splitter
    captured_keys = []

    splitter.define_singleton_method(:with_advisory_lock) do |key, &block|
      captured_keys << key
      block.call
    end

    stub_mixin_assets(splitter, [ { "asset_id" => SecureRandom.uuid, "balance" => "0.5" } ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    assert_equal [ "splitter:#{splitter.id}:collect" ], captured_keys
  end

  test "collect_assets creates a default transfer for each non-zero asset" do
    splitter = persisted_splitter
    asset_id = SecureRandom.uuid
    stub_mixin_assets(splitter, [ { "asset_id" => asset_id, "balance" => "1.25" } ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    transfer = splitter.transfers.find_by(asset_id: asset_id)
    assert_not_nil transfer
    assert_equal "default", transfer.transfer_type
    assert_equal "1.25", transfer.amount.to_s
    assert_equal splitter.uuid, transfer.wallet_id
    assert_equal "assets collection", transfer.memo
    assert_match(/\A[0-9a-f-]{36}\z/, transfer.trace_id)
  end

  test "collect_assets routes the transfer opponent_id at QuillBot.api.client_id" do
    splitter = persisted_splitter
    asset_id = SecureRandom.uuid
    stub_mixin_assets(splitter, [ { "asset_id" => asset_id, "balance" => "0.5" } ])

    with_quill_bot_stub do
      splitter.collect_assets

      transfer = splitter.transfers.find_by(asset_id: asset_id)
      assert_equal QuillBot.api.client_id, transfer.opponent_id
    end
  end

  test "collect_assets skips assets whose balance is zero" do
    splitter = persisted_splitter
    asset_id = SecureRandom.uuid
    stub_mixin_assets(splitter, [
      { "asset_id" => asset_id, "balance" => "0" },
      { "asset_id" => SecureRandom.uuid, "balance" => "0.0" },
      { "asset_id" => SecureRandom.uuid, "balance" => "0.00000000" }
    ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    assert_equal 0, splitter.transfers.count
  end

  test "collect_assets skips an asset that already has an unprocessed transfer" do
    splitter = persisted_splitter
    asset_id = SecureRandom.uuid

    Transfer.create!(
      wallet: splitter,
      asset_id: asset_id,
      amount: "0.1",
      opponent_id: QuillBotStub::FAKE_CLIENT_ID,
      trace_id: SecureRandom.uuid,
      memo: "existing",
      transfer_type: :default
    )

    stub_mixin_assets(splitter, [ { "asset_id" => asset_id, "balance" => "0.5" } ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    assert_equal 1, splitter.transfers.where(asset_id: asset_id).count,
      "expected the existing unprocessed transfer to short-circuit creation"
  end

  test "collect_assets does NOT skip an asset whose existing transfer is processed" do
    splitter = persisted_splitter
    asset_id = SecureRandom.uuid

    Transfer.create!(
      wallet: splitter,
      asset_id: asset_id,
      amount: "0.1",
      opponent_id: QuillBotStub::FAKE_CLIENT_ID,
      trace_id: SecureRandom.uuid,
      memo: "already done",
      transfer_type: :default,
      processed_at: 5.minutes.ago
    )

    stub_mixin_assets(splitter, [ { "asset_id" => asset_id, "balance" => "0.5" } ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    assert_equal 2, splitter.transfers.where(asset_id: asset_id).count
  end

  test "collect_assets processes a mix of fresh, zero-balance, and duplicate assets" do
    splitter = persisted_splitter

    asset_zero      = SecureRandom.uuid
    asset_fresh     = SecureRandom.uuid
    asset_duplicate = SecureRandom.uuid

    Transfer.create!(
      wallet: splitter,
      asset_id: asset_duplicate,
      amount: "0.1",
      opponent_id: QuillBotStub::FAKE_CLIENT_ID,
      trace_id: SecureRandom.uuid,
      memo: "duplicate",
      transfer_type: :default
    )

    stub_mixin_assets(splitter, [
      { "asset_id" => asset_zero,      "balance" => "0" },
      { "asset_id" => asset_fresh,     "balance" => "2.5" },
      { "asset_id" => asset_duplicate, "balance" => "7.0" }
    ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    assert_equal 0, splitter.transfers.where(asset_id: asset_zero).count
    assert_equal 1, splitter.transfers.where(asset_id: asset_fresh).count
    assert_equal 1, splitter.transfers.where(asset_id: asset_duplicate).count,
      "duplicate should NOT add a second transfer"
  end

  test "collect_assets skips when the advisory lock cannot be acquired" do
    splitter = persisted_splitter
    asset_id = SecureRandom.uuid

    splitter.define_singleton_method(:with_advisory_lock) do |_key, &_block|
      # Mimic the real concern's branch where pg_try_advisory_lock returns
      # false — the block is never called.
    end

    stub_mixin_assets(splitter, [ { "asset_id" => asset_id, "balance" => "1.0" } ])

    with_quill_bot_stub do
      splitter.collect_assets
    end

    assert_equal 0, splitter.transfers.count,
      "an un-acquired advisory lock should result in zero transfers created"
  end

  private

  # Build an unsaved Splitter record that bypasses the MixinNetworkUser
  # `setup_attributes` callback (which would otherwise reach for
  # QuillBot.api.create_user) and lets the caller set name/uuid/etc directly.
  def build_splitter(overrides: {})
    splitter = Splitter.new
    splitter.define_singleton_method(:setup_attributes) { }
    splitter.assign_attributes({
      uuid: SecureRandom.uuid,
      name: "Splitter #{SecureRandom.hex(4)}",
      pin_token: "stub-pin-token",
      private_key: "stub-private-key",
      session_id: SecureRandom.uuid
    }.merge(overrides))
    splitter
  end

  # Save the splitter with validations skipped — this test file never depends
  # on the actual `before_validation` chain (which would otherwise need
  # QuillBot.api.create_user stubbing).
  def persisted_splitter
    build_splitter.tap { |s| s.save(validate: false) }
  end

  # Replace `mixin_api` on the splitter instance so that `assets` returns
  # whatever fixture list the caller wants, without exercising the real
  # MixinBot::API surface.
  def stub_mixin_assets(splitter, assets)
    api = Object.new
    api.define_singleton_method(:assets) { { "data" => assets } }
    splitter.define_singleton_method(:mixin_api) { api }
  end
end
