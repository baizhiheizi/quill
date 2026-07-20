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

  test "preload_user_aggregates is a no-op when @users is empty" do
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql] if payload[:sql] =~ /FROM\s+"orders"|FROM\s+"transfers"/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      @controller.send(:preload_user_aggregates, [])
    end

    assert_empty queries, "expected no aggregate queries on empty user list, got: #{queries.inspect}"
  end

  test "preload_user_aggregates emits at most 3 batched aggregate queries regardless of user count" do
    # Arrange: deterministic Order + Transfer data so the preloader has
    # non-trivial rows to group. Insert directly with `insert_all` to skip
    # `Order#setup_attributes` (which requires a `payment` association) and
    # other callbacks that aren't relevant to the aggregator test.
    article = articles(:published_free)
    currency = currencies(:btc)
    reader_one = users(:reader_one)
    reader_two = users(:reader_two)

    now = Time.current
    Order.insert_all!([
      {
        buyer_id: reader_one.id,
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
        buyer_id: reader_two.id,
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
        opponent_id: reader_one.mixin_uuid,
        amount: 5.0,
        transfer_type: Transfer.transfer_types[:author_revenue],
        created_at: now,
        updated_at: now
      }
    ])

    users = User.where.not(id: nil).to_a

    # Act: invoke the preloader and capture aggregate-shaped queries.
    aggregate_queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      sql = payload[:sql]
      next unless sql =~ /FROM\s+"orders"|FROM\s+"transfers"/i
      aggregate_queries << sql if sql =~ /GROUP BY|SUM\(|COUNT\(\*\)/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      @controller.send(:preload_user_aggregates, users)
    end

    # Assert: regardless of how many users are in the fixture set, the
    # preloader should emit at most 3 GROUP BY aggregate queries (one per
    # metric), not 3 × N per-user queries.
    assert_operator aggregate_queries.size, :<=, 3,
      "expected <= 3 batched aggregate queries, got #{aggregate_queries.size}:\n#{aggregate_queries.first(5).join("\n")}"
  end

  test "preload_user_aggregates returns correct values for each user" do
    article = articles(:published_free)
    currency = currencies(:btc)
    reader_one = users(:reader_one)
    reader_two = users(:reader_two)

    now = Time.current
    Order.insert_all!([
      {
        buyer_id: reader_one.id,
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
      }
    ])
    Transfer.insert_all!([
      {
        asset_id: currency.asset_id,
        trace_id: SecureRandom.uuid,
        opponent_id: reader_two.mixin_uuid,
        amount: 0.0001,
        transfer_type: Transfer.transfer_types[:author_revenue],
        created_at: now,
        updated_at: now
      }
    ])

    users = User.where.not(id: nil).to_a

    @controller.send(:preload_user_aggregates, users)

    reader_one_row = users.find { |u| u.id == reader_one.id }
    assert_equal 1, reader_one_row.bought_articles_count
    assert_in_delta 10.0, reader_one_row.payment_total_usd, 0.0001
    assert_in_delta 0.0, reader_one_row.author_revenue_total_usd, 0.0001

    reader_two_row = users.find { |u| u.id == reader_two.id }
    assert_equal 0, reader_two_row.bought_articles_count
    assert_in_delta 0.0, reader_two_row.payment_total_usd, 0.0001
    # 0.0001 BTC * $50000/BTC = $5 USD.
    assert_in_delta 5.0, reader_two_row.author_revenue_total_usd, 0.0001
  end

  test "index does not fire per-row SELECTs for the avatar chain" do
    # Regression guard for the avatar-chain preload on
    # `Admin::UsersController#index`. The `_user` partial renders
    # `shared/_avatar` (via `admin/users/_field`), which walks
    # `user.avatar_image_thumb` → `authorization&.raw["avatar_url"]` +
    # `avatar_attachment.blob.variant_records`. Without
    # `includes(*user_field_preloads)` the controller fires 1 SELECT per
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
