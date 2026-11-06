# frozen_string_literal: true

require "test_helper"

# Covers `Users::Scopable`, the concern on `User` that groups the
# blocked/provider/active scopes plus the order-by-total query helpers used
# by the admin and search UIs.
#
# Four scopes are pinned here:
#   - `only_blocked` / `without_blocked` (disjoint, union = every row)
#   - `only_mixin_messenger` (provider filter used by
#     `Admin::UsersController#query`)
#   - `only_validated` (predicate filter also used by
#     `Admin::UsersController#query`)
#
# The aggregate `order_by_*` scopes are already covered in `user_test.rb`
# because they pull in fixture rows. We keep that there — re-pinning them
# here would only duplicate the existing 8 assertions.
#
# Note on the provider-filter scopes: each writes
# `where(authorization: { provider: ... })`, which only resolves once a
# JOIN brings in `user_authorizations` aliased as `authorization`. The
# tests exercise them via `joins(:authorization)` so the JOIN is explicit.
# In production, `Admin::UsersController#index` chains
# `includes(*User::AVATAR_PRELOADS)` (which preloads `:authorization`); Rails
# switches `includes` to an eager-load `LEFT OUTER JOIN` once the WHERE
# references the included table's columns, so the production chain works
# via the same JOIN the tests use here.
class Users::ScopableTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @reader_one = users(:reader_one)
    @reader_two = users(:reader_two)
    @blocked = users(:blocked_reader)
  end

  # --- only_blocked / without_blocked --------------------------------------

  test "without_blocked excludes rows where blocked_at is set" do
    visible = User.without_blocked

    assert_includes visible, @author
    assert_includes visible, @reader_one
    assert_not_includes visible, @blocked
  end

  test "only_blocked returns rows where blocked_at is set" do
    hidden = User.only_blocked

    assert_includes hidden, @blocked
    assert_not_includes hidden, @author
    assert_not_includes hidden, @reader_one
  end

  test "only_blocked and without_blocked are disjoint" do
    visible_ids = User.without_blocked.pluck(:id)
    hidden_ids = User.only_blocked.pluck(:id)

    assert_empty(visible_ids & hidden_ids,
      "only_blocked and without_blocked overlap on: #{(visible_ids & hidden_ids).inspect}")
  end

  test "without_blocked ∪ only_blocked covers every user row" do
    every_id = User.pluck(:id).sort
    union = (User.without_blocked.pluck(:id) + User.only_blocked.pluck(:id)).uniq.sort

    assert_equal every_id, union
  end

  # --- provider-filter scopes (admin/users_controller#query) --------------

  test "only_mixin_messenger returns users whose authorization has provider mixin" do
    mixin_users = User.joins(:authorization).only_mixin_messenger

    assert_includes mixin_users, @author
    assert_includes mixin_users, @reader_one
    assert_includes mixin_users, @reader_two
  end

  # --- only_validated -------------------------------------------------------

  test "only_validated returns rows where validated_at is set" do
    @reader_one.update_column(:validated_at, 2.days.ago)
    @author.update_column(:validated_at, nil)

    validated = User.only_validated

    assert_includes validated, @reader_one
    assert_not_includes validated, @author
  end
end
