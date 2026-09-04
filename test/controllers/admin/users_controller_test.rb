# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionController::TestCase
  tests Admin::UsersController

  setup do
    @admin = administrators(:one)
    # `Admin::BaseController#authenticate_admin!` only checks
    # `current_admin.blank?`. We bypass it by setting the session directly.
    @request.session[:current_admin_id] = @admin.id
  end

  # Deterministic Order + Transfer rows for the aggregate assertions.
  # `insert_all!` skips `Order#setup_attributes` (which requires a `payment`
  # association) and other callbacks that aren't relevant to the aggregator.
  def seed_orders_and_transfers!
    article = articles(:published_free)
    currency = currencies(:btc)
    now = Time.current

    Order.insert_all!([
      {
        buyer_id: users(:reader_one).id,
        seller_id: users(:author).id,
        item_type: "Article",
        item_id: article.id,
        asset_id: currency.asset_id,
        trace_id: SecureRandom.uuid,
        order_type: Order.order_types[:buy_article],
        total: 10.0,
        value_btc: 0.0,
        value_usd: 10.0,
        state: "paid",
        created_at: now,
        updated_at: now
      },
      {
        buyer_id: users(:reader_two).id,
        seller_id: users(:author).id,
        item_type: "Article",
        item_id: article.id,
        asset_id: currency.asset_id,
        trace_id: SecureRandom.uuid,
        order_type: Order.order_types[:buy_article],
        total: 20.0,
        value_btc: 0.0,
        value_usd: 20.0,
        state: "paid",
        created_at: now,
        updated_at: now
      }
    ])

    Transfer.insert_all!([
      {
        wallet_id: nil,
        asset_id: currency.asset_id,
        trace_id: SecureRandom.uuid,
        opponent_id: users(:reader_one).mixin_uuid,
        amount: 5.0,
        transfer_type: Transfer.transfer_types[:author_revenue],
        created_at: now,
        updated_at: now
      }
    ])
  end

  test "index primes the aggregate columns with at most 3 batched queries" do
    # Regression guard for the aggregate N+1 on `Admin::UsersController#index`.
    # The `_user` partial renders `bought_articles_count`,
    # `payment_total_usd` and `author_revenue_total_usd` once per row; the
    # naive readers each fire one query per user, so a 24-user page cost ~72
    # queries. `User.preload_aggregates` — called by the controller — must
    # collapse those to 3 GROUP BY queries regardless of how many users are
    # on the page.
    seed_orders_and_transfers!

    aggregate_queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      sql = payload[:sql]
      next unless sql =~ /FROM\s+"orders"|FROM\s+"transfers"/i
      aggregate_queries << sql if sql =~ /GROUP BY|SUM\(|COUNT\(\*\)/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get :index
    end

    assert_response :success
    assert_operator aggregate_queries.size, :<=, 3,
      "expected <= 3 batched aggregate queries, got #{aggregate_queries.size}:\n#{aggregate_queries.first(5).join("\n")}"

    users = @controller.instance_variable_get(:@users)
    primed_one = users.find { |u| u.id == users(:reader_one).id }
    primed_two = users.find { |u| u.id == users(:reader_two).id }

    # The page renders the primed values — proving the bulk pass and the
    # per-user readers agree without the controller touching model internals.
    assert_equal 1, primed_one.bought_articles_count
    assert_in_delta 10.0, primed_one.payment_total_usd, 0.0001
    assert_equal 1, primed_two.bought_articles_count
    assert_in_delta 20.0, primed_two.payment_total_usd, 0.0001
  end

  test "index does not fire per-row SELECTs for the avatar chain" do
    # Regression guard for the avatar-chain preload on
    # `Admin::UsersController#index`. The `_user` partial renders
    # `shared/_avatar` (via `admin/users/_field`), which walks
    # `user.avatar_image_thumb` → `authorization&.raw["avatar_url"]` +
    # `avatar_attachment.blob.variant_records`. Without
    # `includes(*User::AVATAR_PRELOADS)` the controller fires 1 SELECT per
    # row for each step of that chain — ~3-5 SELECTs per user on a 24-user
    # admin page. With the preload the chain is resolved in O(1) SELECTs
    # regardless of the page size.
    #
    # The test uses `get :index` so the controller walks the partial for
    # every fixture user. We only assert that the per-row tables
    # (`user_authorizations`, `active_storage_attachments`,
    # `active_storage_blobs`, `active_storage_variant_records`) are not
    # queried without `WHERE users.id IN (...)` batching — i.e. the test
    # fails when the controller drops the `includes`.
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      sql = payload[:sql]
      next unless sql =~ /FROM\s+"user_authorizations"\s|FROM\s+"active_storage_attachments"\s|FROM\s+"active_storage_blobs"\s|FROM\s+"active_storage_variant_records"\s/i
      # A correctly-preloaded chain uses a single IN-batched SELECT per
      # table — the partial never re-fires SELECTs with a `users.id = ?`
      # equality predicate because the records are already in the
      # identity map. Rails emits IN clauses as either raw integer lists
      # (`IN (1, 2, 3)`) or parameterized placeholders (`IN ($1, $2, $3)`);
      # either form is batched and we skip both.
      next if sql =~ /IN\s*\(\s*\d+\s*(?:,\s*\d+\s*)+\)/i
      next if sql =~ /IN\s*\(\s*\$\d+\s*(?:,\s*\$\d+\s*)+\)/i
      next if sql =~ /IN\s*\(\s*SELECT\s+/i
      queries << sql
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get :index
    end

    assert_response :success
    assert_empty queries,
      "expected no per-row avatar SELECTs after the preload, got #{queries.size}:\n#{queries.first(5).join("\n")}"
  end
end
