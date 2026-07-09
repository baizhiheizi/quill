# frozen_string_literal: true

require "test_helper"

class Admin::MixinNetworkSnapshotsControllerTest < ActionController::TestCase
  tests Admin::MixinNetworkSnapshotsController

  setup do
    @admin = administrators(:one)
    # `Admin::BaseController#authenticate_admin!` only checks
    # `current_admin.blank?`. We bypass it by setting the session directly.
    @request.session[:current_admin_id] = @admin.id
  end

  # Admin mixin network snapshots N+1 regression guard.
  #
  # `Admin::MixinNetworkSnapshotsController#index` renders
  # `app/views/admin/mixin_network_snapshots/_mixin_network_snapshot.html.erb`,
  # which walks up to four belongs_to + a polymorphic avatar chain per row:
  #   - `wallet` (MixinNetworkUser by user_id)
  #   - `opponent_wallet` (MixinNetworkUser by opponent_id)
  #   - `currency` (Currency by asset_id)
  #   - `opponent` (User by opponent_id/mixin_uuid) — renders the avatar
  #     field partial, which walks `avatar_image_thumb` (4-5 SELECTs)
  #
  # Without the eager-load, a 50-row admin page fires ~200 SELECTs for
  # the four belongs_to alone and up to ~250 more for the opponent avatar
  # chain. After the fix: ~7 SELECTs total, regardless of page size.
  #
  # This test pins the eager-load shape so a future regression that drops
  # one of the chains (e.g. someone refactoring the partial or the
  # controller) is caught immediately.

  test "index_includes preloads wallet, opponent_wallet, currency, and opponent (with avatar chain)" do
    includes = @controller.send(:index_includes)

    assert_includes includes, :wallet
    assert_includes includes, :opponent_wallet
    assert_includes includes, :currency
    # The opponent chain must be preloaded with the avatar field chain
    # (authorization + active_storage fan-out) so the partial renders flat.
    opponent_chain = includes.find { |v| v.is_a?(Hash) && v.key?(:opponent) }
    assert opponent_chain, "expected opponent in preload chain, got #{includes.inspect}"
    assert_equal(
      Admin::BaseController.new.admin_user_field_preloads,
      opponent_chain[:opponent]
    )
  end
end
