# frozen_string_literal: true

require "test_helper"

class Admin::MixinNetworkUsersControllerTest < ActionController::TestCase
  tests Admin::MixinNetworkUsersController

  setup do
    @admin = administrators(:one)
    # `Admin::BaseController#authenticate_admin!` only checks
    # `current_admin.blank?`. We bypass it by setting the session directly.
    @request.session[:current_admin_id] = @admin.id
  end

  # Admin mixin network users N+1 regression guard.
  #
  # `Admin::MixinNetworkUsersController#index` renders
  # `app/views/admin/mixin_network_users/_mixin_network_user.html.erb`,
  # which dispatches on the polymorphic `owner` association:
  #   - `mixin_network_user.owner.is_a?(Article)` → renders
  #     `admin/articles/_field` (no avatar chain).
  #   - `mixin_network_user.owner.is_a?(User)`    → renders
  #     `admin/users/_field` → `shared/_avatar`, which walks
  #     `user.avatar_image_thumb` → `authorization.raw["avatar_url"]` +
  #     `avatar_attachment.blob.variant_records`. Without a primed preload,
  #     each User-owner row fires ~4-5 SELECTs (authorization + attachment +
  #     blob + variant_records). Article-owner rows don't walk the chain.
  #
  # Without the user_field_preloads nested under `:owner`, a 50-row admin
  # page of User-owner MixinNetworkUsers fires ~200-250 extra SELECTs. After
  # the fix: ~7 SELECTs total, regardless of page size (2 polymorphic IN-batch
  # SELECTs for the owner rows + 4-5 IN-batch SELECTs for the avatar chain).
  #
  # This test pins the preload shape so a future regression that drops the
  # user-shaped preload chain (e.g. someone refactoring the partial or the
  # controller) is caught immediately.
  test "index_includes preloads owner with the user_field_preloads chain for User-owner rows" do
    includes = @controller.send(:index_includes)

    # Only one shape in the chain — the polymorphic owner + avatar fan-out.
    assert_equal 1, includes.size, "expected exactly one preload shape, got #{includes.inspect}"

    owner_chain = includes.first
    assert owner_chain.is_a?(Hash), "expected Hash shape, got #{owner_chain.inspect}"
    assert owner_chain.key?(:owner), "expected :owner in preload chain, got #{owner_chain.inspect}"

    # The :owner chain must use the canonical admin_user_field_preloads shape
    # so User-owner rows render flat. Article-owner rows ignore the
    # user-shaped keys (Rails 7+ polymorphic preload only follows keys present
    # on each target model), so no extra SELECTs fire on that branch.
    assert_equal(
      Admin::BaseController.new.admin_user_field_preloads,
      owner_chain[:owner],
      "owner chain should match admin_user_field_preloads so User-owner rows " \
        "render the avatar partial without N+1s"
    )
  end
end
