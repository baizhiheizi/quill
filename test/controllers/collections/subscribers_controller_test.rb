# frozen_string_literal: true

require "test_helper"

class Collections::SubscribersControllerTest < ActionDispatch::IntegrationTest
  # Public-side `Collections::SubscribersController#index` regression
  # guard.
  #
  # Renders `app/views/collections/subscribers/index.html.erb` and walks
  # `@collection.subscribers` (a `has_many :through` relation through
  # `:buy_orders`). Without these tests, two regressions can slip in
  # silently:
  #   1. the 404 path on unlisted collections (already covered by the
  #      BaseController tests, but pinned here for the subscribers path
  #      so a future refactor of the base doesn't accidentally break it
  #      for this child).
  #   2. the per-row N+1 in `shared/_avatar` and
  #      `subscribe_users/_subscribe_button` — guarded by an explicit
  #      query-count assertion.
  setup do
    @author = users(:author)
    @collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Listed Collection",
      symbol: "LC",
      description: "Listed",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
    @subscriber_one = users(:reader_one)
    @subscriber_two = users(:reader_two)
    create_buy_collection_order!(collection: @collection, buyer: @subscriber_one)
    create_buy_collection_order!(collection: @collection, buyer: @subscriber_two)
  end

  test "index renders successfully for a listed collection with subscribers" do
    get collection_subscribers_path(collection_uuid: @collection.uuid)

    assert_response :success
    assert_match @subscriber_one.name, response.body
    assert_match @subscriber_two.name, response.body
  end

  test "index renders empty-state copy when the collection has no subscribers" do
    empty = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Empty Listed",
      symbol: "EL",
      description: "Empty",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )

    get collection_subscribers_path(collection_uuid: empty.uuid)

    assert_response :success
    assert_match I18n.t("no_record"), response.body
  end

  test "index returns 404 for an unlisted collection (inherited from base)" do
    unlisted = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Hidden Collection",
      symbol: "HC",
      description: "Hidden",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "drafted"
    )

    get collection_subscribers_path(collection_uuid: unlisted.uuid)

    assert_response :not_found
  end

  test "index returns 404 for a missing collection uuid (inherited from base)" do
    get collection_subscribers_path(collection_uuid: SecureRandom.uuid)

    assert_response :not_found
  end

  test "index preloads the user chain so the subscriber partial fires no per-row queries" do
    # Build up enough subscribers to make a per-row N+1 visible — 5
    # distinct buyer orders, each going through `shared/_avatar` and
    # `subscribe_users/_subscribe_button`.
    3.times do |i|
      buyer = User.create!(
        name: "Bulk Subscriber #{i}",
        uid: "99910#{i}",
        mixin_id: "99910#{i}",
        mixin_uuid: SecureRandom.uuid
      )
      create_buy_collection_order!(collection: @collection, buyer: buyer)
    end

    # Warm up any one-time schema / connection queries so the count
    # below reflects only the action itself, not framework boot.
    get collection_subscribers_path(collection_uuid: @collection.uuid)
    assert_response :success

    queries = []
    counter = ->(_n, _s, _f, _id, payload) do
      sql = payload[:sql] || payload[:name] || ""
      queries << sql unless sql.start_with?("SCHEMA") || sql.include?("TRANSACTION")
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get collection_subscribers_path(collection_uuid: @collection.uuid)
    end

    assert_response :success
    # The action fires:
    #   1. SELECT @collection (base)
    #   2. pagy count
    #   3. pagy offset SELECT (subscribers + preloads)
    #   4. pagy page SELECT (subscribers + preloads) — sometimes merged
    # With preloads in place, the subscriber partial should NOT fire
    # any additional SELECT for `users`, `active_storage_attachments`,
    # `active_storage_blobs`, `active_storage_variant_records`, or
    # `authorizations`. Without preloads each subscriber adds ~5
    # SELECTs; with 5 subscribers that's 25 extra SELECTs. Cap at 12
    # to give the pagy implementation + turbo_stream fallback room to
    # breathe while still catching a regression.
    assert_operator queries.size, :<=, 12,
      "expected ≤12 SQL queries after preloads, got #{queries.size}:\n#{queries.join("\n")}"
  end

  private

  # Build a `buy_collection` Order pointing at a Payment whose
  # `generate_order!` callback is stubbed out — we create the Order
  # manually so the test exercises the controller and not the
  # `Payment → generate_order!` callback. Mirrors `create_payment_for!`
  # in `test/notifiers/collection_bought_notifier_test.rb`.
  def create_buy_collection_order!(collection:, buyer:)
    trace_id = SecureRandom.uuid

    payment = stub_notifications! do
      p = Payment.new(
        amount: collection.price,
        raw: {
          "amount" => collection.price.to_s,
          "asset_id" => collection.asset_id,
          "memo" => build_payment_memo(type: "BUY", collection: collection),
          "opponent_id" => buyer.mixin_uuid,
          "snapshot_id" => SecureRandom.uuid,
          "trace_id" => trace_id
        },
        asset_id: collection.asset_id,
        snapshot_id: SecureRandom.uuid,
        trace_id: trace_id,
        payer: buyer,
        state: "completed"
      )
      p.define_singleton_method(:generate_order!) { }
      p.save!(validate: false)
      p
    end

    Order.create!(
      buyer: buyer,
      seller: collection.author,
      item: collection,
      payment: payment,
      order_type: :buy_collection,
      trace_id: payment.trace_id,
      asset_id: collection.asset_id,
      total: collection.price,
      value_btc: 0,
      value_usd: 0,
      state: "completed"
    )
  end
end
