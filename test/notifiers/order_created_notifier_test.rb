# frozen_string_literal: true

require "test_helper"

class OrderCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:reader_one)
    @author = users(:author)
    @article = articles(:published_paid)
    @buy_order = create_buy_order!(article: @article, buyer: @buyer)
  end

  test "deliver creates a visible web notification for buy_article orders" do
    deliver_notifier!(
      OrderCreatedNotifier,
      record: @buy_order,
      order: @buy_order,
      recipient: @buyer
    )

    notification = notification_for(@buyer)

    assert_equal "OrderCreatedNotifier", Noticed::Event.last.type
    assert_equal @buy_order, notification.params[:order]
    assert_includes notification.message,
      I18n.t("notifiers.order_created_notifier.notification.bought")
    assert_includes notification.message, @article.title
    assert notification.visible_in_web?
  end

  test "message uses 'rewarded' for reward_article orders" do
    reward_order = create_reward_order!(article: @article, buyer: @buyer)

    deliver_notifier!(
      OrderCreatedNotifier,
      record: reward_order,
      order: reward_order,
      recipient: @buyer
    )

    notification = notification_for(@buyer)

    assert_includes notification.message,
      I18n.t("notifiers.order_created_notifier.notification.rewarded")
    assert_includes notification.message, @article.title
  end

  test "url points to the article for buy_article orders" do
    deliver_notifier!(
      OrderCreatedNotifier,
      record: @buy_order,
      order: @buy_order,
      recipient: @buyer
    )

    notification = notification_for(@buyer)

    assert_includes notification.url, @article.uuid
  end

  test "does not enqueue mixin bot delivery for non-messenger recipients" do
    deliver_notifier!(
      OrderCreatedNotifier,
      record: @buy_order,
      order: @buy_order,
      recipient: @buyer
    )

    perform_enqueued_jobs only: Noticed::EventJob

    assert_no_enqueued_jobs only: DeliveryMethods::MixinBot
  end

  private

  def create_reward_order!(article:, buyer:)
    trace_id = SecureRandom.uuid
    payment = Payment.new(
      amount: article.price,
      raw: { "amount" => article.price.to_s, "asset_id" => article.asset_id },
      asset_id: article.asset_id,
      snapshot_id: SecureRandom.uuid,
      trace_id: trace_id,
      payer: buyer,
      state: "completed"
    )
    payment.define_singleton_method(:generate_order!) { }
    payment.save!(validate: false)

    Order.create!(
      buyer: buyer,
      seller: article.author,
      item: article,
      payment: payment,
      order_type: :reward_article,
      trace_id: payment.trace_id,
      asset_id: article.asset_id,
      total: article.price,
      value_btc: 0.0,
      value_usd: 0.0
    )
  end
end
