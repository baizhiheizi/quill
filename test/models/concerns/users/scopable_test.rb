# frozen_string_literal: true

require "test_helper"

# Covers `Users::Scopable`, the concern on `User` that groups the
# authorization/blocked/provider/active scopes plus the order-by-total
# query helpers used by the admin and search UIs.
#
# Five scopes are pinned here:
#   - `with_authorization` (preload scope — issues a separate
#     `user_authorizations` SELECT so iterating `.authorization` does not
#     trigger an N+1)
#   - `only_blocked` / `without_blocked` (disjoint, union = every row)
#   - `only_mixin_messenger` / `only_fennec` / `only_mvm` (provider filters
#     used by `Admin::UsersController#query`)
#   - `only_email_verified` / `only_validated` (predicate filters also used
#     by `Admin::UsersController#query`)
#
# The aggregate `order_by_*` scopes are already covered in `user_test.rb`
# because they pull in fixture rows. We keep that there — re-pinning them
# here would only duplicate the existing 8 assertions.
#
# Note on the provider-filter scopes: each writes
# `where(authorization: { provider: ... })`, which only resolves once a
# JOIN brings in `user_authorizations` aliased as `authorization`. The
# tests exercise them via `joins(:authorization)` so the JOIN is explicit.
# In production, `Admin::UsersController#preload_user_aggregates` chains
# `with_authorization` (which is `includes(:authorization)`); Rails
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

  # --- with_authorization --------------------------------------------------

  test "with_authorization issues a separate preload SELECT for user_authorizations" do
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }

    rows = nil
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      rows = User.with_authorization.to_a
    end

    preload_query = queries.grep(/FROM "user_authorizations"/)
    assert_equal 1, preload_query.size,
      "expected exactly 1 user_authorizations preload SELECT, got: #{preload_query.inspect}"
    assert_includes rows, @author
  end

  test "with_authorization avoids the N+1 on .authorization inside the loop" do
    rows = User.with_authorization.to_a

    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      rows.each(&:authorization)
    end

    assert_empty queries,
      "with_authorization should have preloaded — got extra queries: #{queries.inspect}"
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

  test "only_fennec returns users whose authorization has provider fennec" do
    fennec_user = User.create!(
      uid: "200001",
      name: "Fennec Reader",
      mixin_id: "200001",
      mixin_uuid: "d5555555-5555-4555-8555-555555555555",
      locale: :en
    )
    fennec_user.user_authorizations.create!(
      provider: :fennec,
      uid: "fennec-reader-uid",
      raw: { "user_id" => "fennec-reader-uid" }
    )

    result = User.joins(:authorization).only_fennec

    assert_includes result, fennec_user
    assert_not_includes result, @author
  end

  test "only_mvm returns users whose authorization has provider mvm_eth" do
    mvm_user = User.create!(
      uid: "300001",
      name: "MVM Reader",
      mixin_id: "300001",
      mixin_uuid: "e6666666-6666-4666-8666-666666666666",
      locale: :en
    )
    mvm_user.user_authorizations.create!(
      provider: :mvm_eth,
      uid: "mvm-reader-uid",
      raw: { "user_id" => "mvm-reader-uid" }
    )

    result = User.joins(:authorization).only_mvm

    assert_includes result, mvm_user
    assert_not_includes result, @author
  end

  test "only_mixin_messenger and only_fennec are disjoint" do
    mixin_ids = User.joins(:authorization).only_mixin_messenger.pluck(:id)
    fennec_ids = User.joins(:authorization).only_fennec.pluck(:id)

    assert_empty(mixin_ids & fennec_ids,
      "only_mixin_messenger and only_fennec overlap on: #{(mixin_ids & fennec_ids).inspect}")
  end

  # --- only_email_verified / only_validated --------------------------------

  test "only_email_verified returns rows where email_verified_at is set" do
    @reader_one.update_column(:email_verified_at, 1.day.ago)
    @author.update_column(:email_verified_at, nil)
    @reader_two.update_column(:email_verified_at, nil)

    verified = User.only_email_verified

    assert_includes verified, @reader_one
    assert_not_includes verified, @author
    assert_not_includes verified, @reader_two
  end

  test "only_validated returns rows where validated_at is set" do
    @reader_one.update_column(:validated_at, 2.days.ago)
    @author.update_column(:validated_at, nil)

    validated = User.only_validated

    assert_includes validated, @reader_one
    assert_not_includes validated, @author
  end

  test "only_email_verified and only_validated are independent predicates" do
    # A row with email_verified_at but no validated_at must show in
    # only_email_verified but not only_validated; the inverse symmetric.
    @reader_one.update_columns(email_verified_at: 1.day.ago, validated_at: nil)
    @reader_two.update_columns(email_verified_at: nil, validated_at: 2.days.ago)

    verified_ids = User.only_email_verified.pluck(:id)
    validated_ids = User.only_validated.pluck(:id)

    assert_includes verified_ids, @reader_one.id
    assert_not_includes verified_ids, @reader_two.id
    assert_includes validated_ids, @reader_two.id
    assert_not_includes validated_ids, @reader_one.id
  end
end
