# frozen_string_literal: true

require "test_helper"

class CollectionBoughtNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @subscriber = users(:reader_two)
    ensure_notification_setting!(@subscriber)
    @collection = create_collection!(author: @author, name: "Featured Bundle")
    @order = build_collection_order(collection: @collection, buyer: @buyer)
  end

  test "deliver creates noticed event and notification records" do
    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(
          CollectionBoughtNotifier,
          record: @order,
          order: @order,
          recipient: @subscriber
        )
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@subscriber)

    assert_equal "CollectionBoughtNotifier", event.type
    assert_equal @order, event.record
    assert_equal @order, notification.params[:order]
    assert_includes notification.message, @buyer.name.truncate(10)
    assert_includes notification.message, @collection.name
    assert notification.visible_in_web?
  end

  test "message includes the bought translation for the collection bought notifier" do
    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_includes notification.message,
                    I18n.t("notifiers.collection_bought_notifier.notification.bought")
  end

  test "message separates the buyer name, translation, and collection name with colons and spaces" do
    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_equal [ @buyer.name.truncate(10),
                   I18n.t("notifiers.collection_bought_notifier.notification.bought"),
                   ":",
                   @collection.name ].join(" "),
                 notification.message
  end

  test "description joins the truncated buyer name and the bought translation" do
    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)
    payload = notification.data

    assert_equal [ @buyer.name.truncate(10),
                   I18n.t("notifiers.collection_bought_notifier.notification.bought") ].join(" "),
                 payload[:description]
  end

  test "url anchors to the bought collection on the collection page" do
    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_includes notification.url, @collection.uuid
  end

  test "data payload exposes the APP_CARD shape for mixin bot delivery" do
    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)
    payload = notification.data

    assert_equal @buyer.avatar_url, payload[:icon_url]
    assert_equal @collection.name.truncate(36), payload[:title]
    assert_includes payload[:description],
                    I18n.t("notifiers.collection_bought_notifier.notification.bought")
    assert_includes payload[:action], @collection.uuid
  end

  test "data title truncates collection names longer than 36 characters" do
    long_name = "x" * 60
    collection = create_collection!(author: @author, name: long_name)
    order = build_collection_order(collection: collection, buyer: @buyer)

    deliver_notifier!(
      CollectionBoughtNotifier,
      record: order,
      order: order,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert_equal long_name.truncate(36), payload[:title]
  end

  test "data description truncates content longer than 72 characters" do
    long_name = "y" * 80
    collection = create_collection!(author: @author, name: long_name)
    order = build_collection_order(collection: collection, buyer: @buyer)

    deliver_notifier!(
      CollectionBoughtNotifier,
      record: order,
      order: order,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert payload[:description].length <= 72
  end

  test "visible_in_web is false when subscriber disables web notifications" do
    @subscriber.notification_setting.update!(article_bought_web: false)

    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    assert_not notification_for(@subscriber).visible_in_web?
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @subscriber.messenger?

    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "may_notify_via_mixin_bot is false when subscriber disabled mixin bot" do
    @subscriber.notification_setting.update!(article_bought_mixin_bot: false)

    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)
    assert_not notification.may_notify_via_mixin_bot?
  end

  test "may_notify_via_mixin_bot is true for messenger recipients by default" do
    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)
    assert notification.may_notify_via_mixin_bot?
  end

  test "deliver does not enqueue a mixin bot message when recipient is not a messenger" do
    reader_two_auth = user_authorizations(:reader_two_auth)
    reader_two_auth.update!(provider: "twitter")

    deliver_notifier!(
      CollectionBoughtNotifier,
      record: @order,
      order: @order,
      recipient: @subscriber
    )

    perform_enqueued_jobs only: Noticed::EventJob
    perform_enqueued_jobs only: DeliveryMethods::MixinBot

    assert_no_enqueued_jobs only: MixinMessages::SendJob
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

  def build_collection_order(collection:, buyer:)
    payment = create_payment_for!(payer: buyer, item: collection, order_type: "BUY")

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

  def create_payment_for!(payer:, item:, order_type:)
    trace_id = SecureRandom.uuid

    stub_notifications! do
      payment = Payment.new(
        amount: item.price,
        raw: {
          "amount" => item.price.to_s,
          "asset_id" => item.asset_id,
          "memo" => build_payment_memo(type: order_type,
                                       article: item.is_a?(Article) ? item : nil,
                                       collection: item.is_a?(Collection) ? item : nil),
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
