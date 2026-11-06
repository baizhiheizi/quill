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

# Covers the `Splitter` model — an empty STI subclass of `MixinNetworkUser`
# that marks the per-asset "sweep" wallet (rows of
# `mixin_network_users.type = "Splitter"`); behavior lives on
# `MixinNetworkUser`.
#
# `pin` is `encrypts`-protected and ActiveRecord encryption is not configured
# in the test credentials (no `active_record_encryption.primary_key`), so the
# tests never exercise the decrypting accessor. They persist through
# `save(validate: false)`, which also skips the `setup_attributes` callback
# chain (it would otherwise reach for QuillBot.api.create_user), so this
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
  end

  test "type is filterable through MixinNetworkUser.where(type: 'Splitter')" do
    splitter = build_splitter(overrides: { name: "Filter Splitter #{SecureRandom.hex(4)}" })
    splitter.save(validate: false)

    assert_includes MixinNetworkUser.where(type: "Splitter").pluck(:uuid), splitter.uuid
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
end
