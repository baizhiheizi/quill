# frozen_string_literal: true

require "test_helper"

class OrderCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@buyer)
  end

  test "deliver creates noticed event and notification records for a buy_article order" do
    order = build_article_order(order_type: :buy_article)

    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@buyer)

    assert_equal "OrderCreatedNotifier", event.type
    assert_equal order, event.record
    assert_equal order, notification.params[:order]
    assert notification.visible_in_web?
  end

  test "message uses the bought translation and includes the article title for buy_article orders" do
    order = build_article_order(order_type: :buy_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.message,
                    I18n.t("notifiers.order_created_notifier.notification.bought")
    assert_includes notification.message, @article.title
  end

  test "message uses the rewarded translation and includes the article title for reward_article orders" do
    order = build_article_order(order_type: :reward_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.message,
                    I18n.t("notifiers.order_created_notifier.notification.rewarded")
    assert_includes notification.message, @article.title
  end

  test "message includes the collection name for buy_collection orders" do
    collection = create_collection!(author: @author, name: "Featured Bundle")
    order = build_collection_order(collection: collection)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.message,
                    I18n.t("notifiers.order_created_notifier.notification.bought")
    assert_includes notification.message, "Featured Bundle"
  end

  test "url anchors to the article on a user_article_url for article items" do
    order = build_article_order(order_type: :buy_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.url, @article.uuid
  end

  test "url anchors to the collection for collection items" do
    collection = create_collection!(author: @author, name: "Featured Bundle")
    order = build_collection_order(collection: collection)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.url, collection.uuid
  end

  test "data payload mirrors the message since the notifier has no APP_CARD shape" do
    order = build_article_order(order_type: :buy_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_equal notification.message, notification.data
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @buyer.messenger?

    order = build_article_order(order_type: :buy_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  private

  def create_collection!(author:, name:)
    Collection.create!(
      uuid: SecureRandom.uuid,
      name: name,
      symbol: "FB",
      description: "Test collection",
      author: author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end

  def build_article_order(order_type:)
    payment = create_payment_for!(payer: @buyer, item: @article, order_type: order_type.to_s.upcase)

    Order.create!(
      buyer: @buyer,
      seller: @article.author,
      item: @article,
      payment: payment,
      order_type: order_type,
      trace_id: payment.trace_id,
      asset_id: @article.asset_id,
      total: @article.price,
      value_btc: 0,
      value_usd: 0,
      state: "completed"
    )
  end

  def build_collection_order(collection:)
    payment = create_payment_for!(payer: @buyer, item: collection, order_type: "BUY")

    Order.create!(
      buyer: @buyer,
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

  def create_payment_for!(payer:, item:, order_type:)
    trace_id = SecureRandom.uuid

    stub_notifications! do
      payment = Payment.new(
        amount: item.price,
        raw: {
          "amount" => item.price.to_s,
          "asset_id" => item.asset_id,
          "memo" => build_payment_memo(type: order_type, article: item.is_a?(Article) ? item : nil, collection: item.is_a?(Collection) ? item : nil),
          "opponent_id" => payer.mixin_uuid,
          "snapshot_id" => SecureRandom.uuid,
          "trace_id" => trace_id
        },
        asset_id: item.asset_id,
        snapshot_id: SecureRandom.uuid,
        trace_id: trace_id,
        payer: payer,
        state: "completed"
      )
      payment.define_singleton_method(:generate_order!) { }
      payment.save!(validate: false)
      payment
    end
  end
end
