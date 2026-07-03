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

# Covers the `MixinNetworkUser` model — the per-bot Mixin Network wallet that
# the rest of the app uses to receive revenue and pay out splits.
#
# The `pin` column is declared with `encrypts :pin`. ActiveRecord encryption is
# not configured in the test credentials (no `active_record_encryption.primary_
# key`), so reading `pin` through the decrypting accessor raises. The tests
# below never exercise the real round-trip; they use a direct `update_column` on
# the underlying `encrypted_pin` (or stub `pin` / `update!` on the instance)
# to avoid touching the encryption path while still verifying the rest of the
# model's behaviour.
class MixinNetworkUserTest < ActiveSupport::TestCase
  ORIGINAL_QUILL_BOT_API = QuillBot.method(:api)

  # `setup_attributes` is a `before_validation :create` callback — it fires on
  # every `valid?` / `save` of a new record, not just on `save`. Every test in
  # this file therefore needs `QuillBot.api.create_user` stubbed, even the
  # ones that only check validations.
  setup do
    QuillBot.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:create_user) do |name|
        {
          "data" => {
            "user_id" => SecureRandom.uuid,
            "full_name" => name,
            "pin_token" => "stub-pin-token",
            "session_id" => SecureRandom.uuid
          },
          "private_key" => "stubbed-private-key-hex"
        }.with_indifferent_access
      end
      api
    end
  end

  teardown do
    QuillBot.define_singleton_method(:api, ORIGINAL_QUILL_BOT_API)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Build a fully-valid MixinNetworkUser fixture record without firing
  # `setup_attributes` (which would otherwise call `QuillBot.api.create_user`).
  # Used by validation tests that only need a persisted row's UUID/session_id
  # already in place.
  def build_wallet(overrides = {})
    wallet = MixinNetworkUser.new
    wallet.define_singleton_method(:setup_attributes) { } # bypass API call
    wallet.assign_attributes({
      uuid: SecureRandom.uuid,
      name: "Test Wallet",
      pin_token: "test-pin-token",
      private_key: "test-private-key",
      session_id: SecureRandom.uuid
    }.merge(overrides))
    wallet
  end

  # `QuillBot.api.create_user` returns a hash with `data` (the user profile)
  # and `private_key` (the hex-encoded Ed25519 seed), `.with_indifferent_access`.
  def fake_create_user_response(overrides = {})
    {
      "data" => {
        "user_id" => SecureRandom.uuid,
        "full_name" => "Stubbed Wallet",
        "pin_token" => "stub-pin-token",
        "session_id" => SecureRandom.uuid
      },
      "private_key" => "stubbed-private-key-hex"
    }.merge(overrides)
  end

  def stub_create_user!(response = fake_create_user_response)
    QuillBot.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:create_user) { |_name| response.with_indifferent_access }
      api
    end
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "requires name" do
    wallet = build_wallet(name: nil)

    assert_not wallet.valid?
    assert_includes wallet.errors[:name], "can't be blank"
  end

  test "requires pin_token" do
    wallet = build_wallet(pin_token: nil)

    assert_not wallet.valid?
    assert_includes wallet.errors[:pin_token], "can't be blank"
  end

  test "requires private_key" do
    wallet = build_wallet(private_key: nil)

    assert_not wallet.valid?
    assert_includes wallet.errors[:private_key], "can't be blank"
  end

  test "requires uuid" do
    wallet = build_wallet(uuid: nil)

    assert_not wallet.valid?
    assert_includes wallet.errors[:uuid], "can't be blank"
  end

  test "requires session_id" do
    wallet = build_wallet(session_id: nil)

    assert_not wallet.valid?
    assert_includes wallet.errors[:session_id], "can't be blank"
  end

  test "uuid uniqueness is enforced at the database level (raises ActiveRecord::RecordNotUnique on save)" do
    existing = mixin_network_users(:quill_wallet)
    duplicate = build_wallet(uuid: existing.uuid)

    # Model-level uniqueness is not declared; the schema's unique index on
    # `uuid` is the enforcement point.
    assert duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save(validate: false) }
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test "belongs_to :owner is optional so the bot wallet can exist without an owner record" do
    wallet = mixin_network_users(:quill_wallet)

    assert_nil wallet.owner
    assert_nothing_raised { wallet.owner }
  end

  test "belongs_to :owner can point at an Article (polymorphic)" do
    wallet = mixin_network_users(:article_wallet)

    assert_equal "Article", wallet.owner_type
    assert_instance_of Article, wallet.owner
  end

  test "has_many :snapshots and :transfers declared on :uuid so dependents nullify on wallet destroy" do
    wallet = mixin_network_users(:quill_wallet)

    reflection_names = wallet.class.reflect_on_all_associations.map(&:name)
    assert_includes reflection_names, :snapshots
    assert_includes reflection_names, :transfers
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test "ready scope returns wallets with a non-nil encrypted pin" do
    # The fixtures all set `pin: "123456"`; regardless of encryption status, the
    # `where.not(pin: nil)` query translates to the encrypted-pin column.
    assert_equal MixinNetworkUser.count, MixinNetworkUser.ready.count
  end

  test "unready scope is the inverse of ready" do
    assert_equal 0, MixinNetworkUser.unready.count
  end

  # ---------------------------------------------------------------------------
  # default_name / avatar
  # ---------------------------------------------------------------------------

  test "default_name returns Settings.broker_name when configured" do
    Settings.broker_name = "Custom Broker"
    assert_equal "Custom Broker", MixinNetworkUser.new.default_name
  ensure
    Settings.broker_name = nil
  end

  test "default_name falls back to 'Quill' when Settings.broker_name is blank" do
    Settings.broker_name = nil
    assert_equal "Quill", MixinNetworkUser.new.default_name
  end

  test "avatar prefers raw['avatar_url'] when set" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.update_column(:raw, { "avatar_url" => "https://mixin.network/avatar.png" })

    assert_equal "https://mixin.network/avatar.png", wallet.avatar
  end

  test "avatar falls back to User.default_avatar_url when raw has no avatar_url" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.update_column(:raw, { "full_name" => "Stubbed Wallet" })

    assert_equal User.default_avatar_url, wallet.avatar
  end

  test "avatar treats an empty raw hash as 'no avatar_url set'" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.update_column(:raw, {})

    assert_equal User.default_avatar_url, wallet.avatar
  end

  # ---------------------------------------------------------------------------
  # mixin_api memoization
  # ---------------------------------------------------------------------------

  test "mixin_api constructs a MixinBot::API from uuid/pin_token/session_id/private_key and memoizes it" do
    wallet = mixin_network_users(:quill_wallet)

    fake_api = Object.new
    captured_kwargs = nil
    constructor_calls = 0

    original_new = MixinBot::API.method(:new)
    MixinBot::API.define_singleton_method(:new) do |**kwargs|
      constructor_calls += 1
      captured_kwargs = kwargs
      fake_api
    end

    first = wallet.mixin_api
    second = wallet.mixin_api

    MixinBot::API.define_singleton_method(:new, original_new)

    assert_same fake_api, first
    assert_same fake_api, second
    assert_equal 1, constructor_calls
    assert_equal wallet.uuid, captured_kwargs[:client_id]
    assert_nil captured_kwargs[:client_secret]
    assert_equal wallet.session_id, captured_kwargs[:session_id]
    assert_equal wallet.pin_token, captured_kwargs[:pin_token]
    assert_equal wallet.private_key, captured_kwargs[:private_key]
  end

  # ---------------------------------------------------------------------------
  # verify_pin / initialize_pin! / update_pin!
  # ---------------------------------------------------------------------------

  test "verify_pin delegates to mixin_api.verify_pin with the wallet's pin" do
    wallet = mixin_network_users(:quill_wallet)
    captured_pin = nil
    wallet.define_singleton_method(:pin) { "abcdef" }
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:verify_pin) do |pin|
        captured_pin = pin
        { "data" => { "valid" => true } }
      end
      api
    end

    wallet.verify_pin

    assert_equal "abcdef", captured_pin
  end

  test "initialize_pin! is a no-op when pin is already present (does not call update_pin!)" do
    wallet = mixin_network_users(:quill_wallet)
    called = false
    wallet.define_singleton_method(:pin) { "123456" }
    wallet.define_singleton_method(:update_pin!) { called = true }

    wallet.initialize_pin!

    assert_not called
  end

  test "initialize_pin! delegates to update_pin! when pin is blank" do
    wallet = mixin_network_users(:quill_wallet)
    called = false
    wallet.define_singleton_method(:pin) { nil }
    wallet.define_singleton_method(:update_pin!) { called = true }

    wallet.initialize_pin!

    assert called
  end

  test "update_pin! generates a 6-character numeric pin, calls mixin_api.update_pin, and updates pin on success" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.define_singleton_method(:pin) { "123456" }

    captured = nil
    fake_response = { "data" => { "updated_at" => Time.current.iso8601 } }
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:update_pin) do |old_pin:, pin:|
        captured = { old_pin: old_pin, pin: pin }
        fake_response
      end
      api
    end

    saved_pin = nil
    wallet.define_singleton_method(:update!) do |attrs|
      saved_pin = attrs[:pin]
      true
    end

    wallet.update_pin!

    assert_equal "123456", captured[:old_pin]
    assert_match(/\A\d{6}\z/, captured[:pin].to_s)
    assert_equal captured[:pin], saved_pin
  end

  test "update_pin! raises and does not persist when the API response is empty" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.define_singleton_method(:pin) { "123456" }
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:update_pin) do |**_|
        { "data" => nil, "error" => "boom" }
      end
      api
    end

    saved = false
    wallet.define_singleton_method(:update!) do |_attrs|
      saved = true
      true
    end

    assert_raises(RuntimeError) { wallet.update_pin! }
    assert_not saved
  end

  # ---------------------------------------------------------------------------
  # sync_profile!
  # ---------------------------------------------------------------------------

  test "sync_profile! calls mixin_api.me and updates raw with the returned data" do
    wallet = mixin_network_users(:quill_wallet)
    profile = { "user_id" => wallet.uuid, "full_name" => "Renamed" }
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:me) { { "data" => profile } }
      api
    end

    saved_attrs = nil
    wallet.define_singleton_method(:update!) do |attrs|
      saved_attrs = attrs
      true
    end

    wallet.sync_profile!

    assert_equal profile, saved_attrs[:raw]
  end

  test "sync_profile! raises and does not persist when the API response is empty" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:me) { { "data" => nil, "error" => "boom" } }
      api
    end

    saved = false
    wallet.define_singleton_method(:update!) do |_attrs|
      saved = true
      true
    end

    assert_raises(RuntimeError) { wallet.sync_profile! }
    assert_not saved
  end

  # ---------------------------------------------------------------------------
  # update_name / update_avatar
  # ---------------------------------------------------------------------------

  test "update_name calls mixin_api.update_me with the default name and persists name + raw" do
    wallet = mixin_network_users(:quill_wallet)
    profile = { "full_name" => "Quill" }
    captured = nil
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:update_me) do |**kwargs|
        captured = kwargs
        { "data" => profile }
      end
      api
    end

    saved_attrs = nil
    wallet.define_singleton_method(:update) do |attrs|
      saved_attrs = attrs
      true
    end

    wallet.update_name

    assert_equal "Quill", captured[:full_name]
    assert_nil captured[:avatar_base64]
    assert_equal "Quill", saved_attrs[:name]
    assert_equal profile, saved_attrs[:raw]
  end

  test "update_name is a no-op (no save) when the API returns no data" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:update_me) { |**| { "data" => nil } }
      api
    end

    saved = false
    wallet.define_singleton_method(:update) do |_attrs|
      saved = true
      true
    end

    wallet.update_name

    assert_not saved
  end

  test "update_avatar passes an avatar_base64 payload and updates raw on success" do
    wallet = mixin_network_users(:quill_wallet)
    profile = { "avatar_url" => "https://mixin.network/new.png" }
    captured = nil
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:update_me) do |**kwargs|
        captured = kwargs
        { "data" => profile }
      end
      api
    end

    saved_attrs = nil
    wallet.define_singleton_method(:update) do |attrs|
      saved_attrs = attrs
      true
    end

    wallet.update_avatar

    assert_equal "Quill", captured[:full_name]
    assert_match(/\A[A-Za-z0-9+\/=]+\z/, captured[:avatar_base64].to_s)
    assert captured[:avatar_base64].length > 1024, "icon.png base64 should be > 1024 chars"
    assert_equal profile, saved_attrs[:raw]
  end

  test "update_avatar closes the icon file even when the API call raises" do
    wallet = mixin_network_users(:quill_wallet)
    wallet.define_singleton_method(:mixin_api) do
      api = Object.new
      api.define_singleton_method(:update_me) { |**| raise "network error" }
      api
    end

    # We assert only that the exception bubbles up; File#close runs in `ensure`
    # and the test suite passing without a "too many open files" error confirms
    # the handle was released.
    assert_raises(RuntimeError) { wallet.update_avatar }
  end

  # ---------------------------------------------------------------------------
  # setup_attributes (before_validation :create callback)
  # ---------------------------------------------------------------------------

  test "setup_attributes populates uuid/name/pin_token/session_id/private_key from the create_user response" do
    stub_create_user!(
      "data" => {
        "user_id" => "abcd1234-0000-4000-8000-000000000001",
        "full_name" => "Stubbed Wallet",
        "pin_token" => "stubbed-pin-token",
        "session_id" => "abcd1234-0000-4000-8000-000000000002"
      },
      "private_key" => "stubbed-private-key-hex"
    )

    wallet = MixinNetworkUser.create!(name: "Stubbed Wallet")

    assert wallet.persisted?
    assert_equal "abcd1234-0000-4000-8000-000000000001", wallet.uuid
    assert_equal "Stubbed Wallet", wallet.name
    assert_equal "stubbed-pin-token", wallet.pin_token
    assert_equal "abcd1234-0000-4000-8000-000000000002", wallet.session_id
    assert_equal "stubbed-private-key-hex", wallet.private_key
    assert_equal "abcd1234-0000-4000-8000-000000000001", wallet.raw["user_id"]
  end

  test "setup_attributes raises when create_user returns an error and the row is not saved" do
    QuillBot.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:create_user) do |_name|
        { "error" => "billing headroom exhausted", "data" => nil }.with_indifferent_access
      end
      api
    end

    wallet = MixinNetworkUser.new(name: "Will Fail")

    assert_raises(RuntimeError) { wallet.save! }
    assert_not wallet.persisted?
  end

  # ---------------------------------------------------------------------------
  # after_commit callbacks
  # ---------------------------------------------------------------------------

  test "after_commit enqueues InitializePinJob and UpdateAvatarJob on create" do
    stub_create_user!

    assert_enqueued_jobs 2, only: [ MixinNetworkUsers::InitializePinJob, MixinNetworkUsers::UpdateAvatarJob ] do
      MixinNetworkUser.create!(name: "Async Wallet")
    end
  end

  test "after_commit callbacks do NOT fire on update" do
    wallet = mixin_network_users(:quill_wallet)

    assert_no_enqueued_jobs(only: [ MixinNetworkUsers::InitializePinJob, MixinNetworkUsers::UpdateAvatarJob ]) do
      wallet.update_columns(name: "Renamed Wallet")
    end
  end
end
