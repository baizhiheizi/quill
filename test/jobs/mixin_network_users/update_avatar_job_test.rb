# frozen_string_literal: true

require "test_helper"

class MixinNetworkUsers::UpdateAvatarJobTest < JobTestCase
  test "perform no-ops for missing mixin network user" do
    assert_nothing_raised { MixinNetworkUsers::UpdateAvatarJob.perform_now(-1) }
  end

  test "perform calls update_avatar on mixin network user" do
    wallet = mixin_network_users(:quill_wallet)
    called = false
    wallet.define_singleton_method(:update_avatar) { called = true }

    stub_class_method(MixinNetworkUser, :find_by, ->(**kwargs) { kwargs[:id] == wallet.id ? wallet : nil }) do
      MixinNetworkUsers::UpdateAvatarJob.perform_now(wallet.id)
    end

    assert called
  end
end
