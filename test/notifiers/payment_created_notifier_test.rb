# frozen_string_literal: true

require "test_helper"

class PaymentCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @payer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@payer)
  end

  test "deliver creates noticed event and notification records" do
    payment = build_payment!

    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(
          PaymentCreatedNotifier,
          record: payment,
          payment: payment,
          recipient: @payer
        )
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@payer)

    assert_equal "PaymentCreatedNotifier", event.type
    assert_equal payment, event.record
    assert_equal payment, notification.params[:payment]
    assert notification.visible_in_web?
  end

  test "message uses the paid translation and includes the price tag" do
    payment = build_payment!

    deliver_notifier!(
      PaymentCreatedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_includes notification.message,
                    I18n.t("notifiers.payment_created_notifier.notification.paid")
    assert_includes notification.message, format("%.8f", payment.amount)
    assert_includes notification.message, payment.currency.symbol
  end

  test "url anchors to the mixin snapshot for the payment" do
    payment = build_payment!

    deliver_notifier!(
      PaymentCreatedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_includes notification.url, payment.snapshot_id
    assert_includes notification.url, "mixin.one/snapshots/"
  end

  test "data payload mirrors the message since the notifier has no APP_CARD shape" do
    payment = build_payment!

    deliver_notifier!(
      PaymentCreatedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_equal notification.message, notification.data
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @payer.messenger?

    payment = build_payment!

    deliver_notifier!(
      PaymentCreatedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "may_notify_via_mixin_bot? returns false for non-messenger recipients" do
    non_messenger = User.create!(
      uid: "200001",
      name: "Non Messenger",
      mixin_uuid: SecureRandom.uuid,
      mixin_id: "200001",
      locale: :en
    )
    non_messenger.create_authorization!(
      provider: :twitter,
      uid: "twitter-uid",
      raw: { "user_id" => "twitter-uid", "name" => "Non Messenger" }
    )

    assert_not non_messenger.messenger?
  end

  private

  def build_payment!(payer: nil, amount: nil, asset_id: nil)
    payer ||= @payer
    amount ||= @article.price
    asset_id ||= @article.asset_id
    trace_id = SecureRandom.uuid

    stub_notifications! do
      payment = Payment.new(
        amount: amount,
        raw: {
          "amount" => amount.to_s,
          "asset_id" => asset_id,
          "memo" => build_payment_memo(type: "BUY", article: @article),
          "opponent_id" => payer.mixin_uuid,
          "snapshot_id" => SecureRandom.uuid,
          "trace_id" => trace_id
        },
        asset_id: asset_id,
        snapshot_id: SecureRandom.uuid,
        trace_id: trace_id,
        payer: payer,
        state: "paid"
      )
      payment.define_singleton_method(:generate_order!) { }
      payment.save!(validate: false)
      payment
    end
  end
end
