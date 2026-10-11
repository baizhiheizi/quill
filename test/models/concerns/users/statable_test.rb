# frozen_string_literal: true

require "test_helper"

# Covers `Users::Statable#has_unread_notification?` and
# `#unread_notifications_count`, the badge counts rendered in the navbar and
# left bar on every page render for authenticated users. Visibility is a
# column on `noticed_notifications`, so the badge counts exactly what the
# notifications index shows.
#
# It also pins `User.preload_aggregates`, the concern's bulk entry point: the
# batched results must equal the per-user computed results, the primed values
# must be served from the concern's own memoization (no controller may write
# it), and the pass must stay at 3 aggregate queries however many users are
# handed to it.
class Users::StatableTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
    @user.notifications.destroy_all
    Noticed::Event.where(record: @user).delete_all
    @web_event = Noticed::Event.create!(type: "CollectionListedNotifier", record: @user)
    @mixin_event = Noticed::Event.create!(type: "UserConnectedNotifier", record: @user)
  end

  test "has_unread_notification? returns false when there are no notifications" do
    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? returns false when only non-web notifications exist" do
    build_notification!(event: @mixin_event, type: "UserConnectedNotifier::Notification", web_visible: false)
    build_notification!(event: @mixin_event, type: "UserSafeRegistrationNotifier::Notification", web_visible: false)

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? returns true when a web notification is unread" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)

    assert @user.has_unread_notification?
    assert_equal 1, @user.unread_notifications_count
  end

  test "the badge no longer overcounts rows the recipient never sees" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: false)

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? ignores read notifications" do
    notification = build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)
    notification.update! read_at: Time.current

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? issues a single query without loading rows into Ruby" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)

    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      @user.has_unread_notification?
    end
    has_unread_queries = queries.grep(/noticed_notifications/)
    assert_equal 1, has_unread_queries.size, "expected a single noticed_notifications SELECT, got: #{has_unread_queries.inspect}"
    assert_match(/LIMIT|EXISTS/i, has_unread_queries.first, "expected LIMIT / EXISTS short-circuit, got: #{has_unread_queries.first}")
  end

  test "the badge query filters on the denormalised column" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)

    sql = @user.notifications.unread.for_web.to_sql

    assert_match(/"web_visible" = (TRUE|true|'t')/, sql)
    assert_no_match(/"type"/, sql)
  end

  # --- User.preload_aggregates ----------------------------------------------

  # Deterministic Order/Transfer rows for the aggregate readers. `insert_all!`
  # skips `Order#setup_attributes` (which needs a `payment` association) and
  # the other callbacks, none of which the aggregate math depends on.
  def seed_aggregates!(reader:, orders: [], transfers: [])
    article = articles(:published_free)
    currency = currencies(:btc)
    now = Time.current

    Order.insert_all!(orders.map do |order|
      {
        buyer_id: order[:buyer].id,
        seller_id: users(:author).id,
        item_type: "Article",
        item_id: article.id,
        asset_id: currency.asset_id,
        trace_id: SecureRandom.uuid,
        order_type: Order.order_types[:buy_article],
        total: order[:value_usd],
        value_btc: 0.0,
        value_usd: order[:value_usd],
        state: "paid",
        created_at: now,
        updated_at: now
      }
    end)

    Transfer.insert_all!(transfers.map do |transfer|
      {
        wallet_id: nil,
        asset_id: currency.asset_id,
        trace_id: SecureRandom.uuid,
        opponent_id: transfer[:opponent].mixin_uuid,
        amount: transfer[:amount],
        transfer_type: Transfer.transfer_types[:author_revenue],
        created_at: now,
        updated_at: now
      }
    end)
  end

  test "preload_aggregates is a no-op on an empty collection" do
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql] if payload[:sql] =~ /FROM\s+"orders"|FROM\s+"transfers"/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      User.preload_aggregates([])
    end

    assert_empty queries, "expected no aggregate queries on an empty user list, got: #{queries.inspect}"
  end

  test "preload_aggregates emits at most 3 aggregate queries regardless of user count" do
    seed_aggregates!(
      reader: users(:reader_one),
      orders: [ { buyer: users(:reader_one), value_usd: 10.0 }, { buyer: users(:reader_two), value_usd: 20.0 } ],
      transfers: [ { opponent: users(:reader_one), amount: 5.0 } ]
    )

    aggregate_queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      sql = payload[:sql]
      next unless sql =~ /FROM\s+"orders"|FROM\s+"transfers"/i
      aggregate_queries << sql if sql =~ /GROUP BY|SUM\(|COUNT\(\*\)/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      User.preload_aggregates(User.all.to_a)
    end

    assert_operator aggregate_queries.size, :<=, 3,
      "expected <= 3 batched aggregate queries, got #{aggregate_queries.size}:\n#{aggregate_queries.first(5).join("\n")}"
  end

  test "preload_aggregates bulk results equal the per-user computed results" do
    seed_aggregates!(
      reader: users(:reader_one),
      orders: [ { buyer: users(:reader_one), value_usd: 10.0 } ],
      transfers: [ { opponent: users(:reader_two), amount: 0.0001 } ]
    )

    bulk = User.order(:id).to_a
    User.preload_aggregates(bulk)
    solo = User.order(:id).to_a

    %i[bought_articles_count payment_total_usd author_revenue_total_usd reader_revenue_total_usd revenue_total_usd].each do |aggregate|
      bulk.zip(solo).each do |primed, naive|
        assert_equal naive.public_send(aggregate), primed.public_send(aggregate),
          "#{aggregate} diverged between the bulk pass and the per-user reader for User##{naive.id}"
      end
    end

    # 0.0001 BTC * $50000/BTC = $5 USD — pins the joined-sum branch, not just
    # the zero/default paths.
    primed_two = bulk.find { |u| u.id == users(:reader_two).id }
    assert_in_delta 5.0, primed_two.author_revenue_total_usd, 0.0001
    assert_equal 0, primed_two.bought_articles_count
  end

  test "primed aggregates are served from memoization without re-querying" do
    seed_aggregates!(reader: users(:reader_one), orders: [ { buyer: users(:reader_one), value_usd: 10.0 } ])

    primed = User.where(id: users(:reader_one).id).to_a
    User.preload_aggregates(primed)
    user = primed.first

    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql] if payload[:sql] =~ /FROM\s+"orders"|FROM\s+"transfers"/i
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      3.times { user.bought_articles_count }
      3.times { user.payment_total_usd }
      3.times { user.author_revenue_total_usd }
    end

    assert_equal 10.0, user.payment_total_usd
    assert_empty queries,
      "expected the primed aggregates to answer every reader without a query, got: #{queries.inspect}"
  end

  test "preload_aggregates leaves the per-user readers correct for users it did not prime" do
    user = users(:reader_one)
    assert_equal 0, user.bought_articles_count
    assert_in_delta 0.0, user.payment_total_usd, 0.0001
    assert_in_delta 0.0, user.author_revenue_total_usd, 0.0001
  end

  private

  def build_notification!(event:, type:, web_visible:)
    Noticed::Notification.create!(
      type: type,
      recipient: @user,
      event: event,
      web_visible: web_visible
    )
  end

  test "memoize_statable rejects keys the concern does not own" do
    error = assert_raises(ArgumentError) do
      users(:reader_one).send(:memoize_statable, :not_a_statable_aggregate, 1)
    end

    assert_match(/not_a_statable_aggregate/, error.message)
  end
end
