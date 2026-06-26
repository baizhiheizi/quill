# frozen_string_literal: true

require "test_helper"

class PaymentRefundedNotifierTest < ActiveSupport::TestCase
  setup do
    @payer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@payer)
  end

  test "deliver creates noticed event and notification records" do
    payment = build_refunded_payment!

    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(
          PaymentRefundedNotifier,
          record: payment,
          payment: payment,
          recipient: @payer
        )
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@payer)

    assert_equal "PaymentRefundedNotifier", event.type
    assert_equal payment, event.record
    assert_equal payment, notification.params[:payment]
    assert notification.visible_in_web?
  end

  test "message uses the refunded translation with the pre-order item title" do
    payment = build_refunded_payment!(pre_order: build_pre_order!(item: @article))

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_equal I18n.t("notifiers.payment_refunded_notifier.notification.refunded",
                        item: @article.title),
                 notification.message
  end

  test "message gracefully handles payments without a pre-order" do
    payment = build_refunded_payment!(pre_order: nil)

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_equal I18n.t("notifiers.payment_refunded_notifier.notification.refunded",
                        item: nil),
                 notification.message
  end

  test "url anchors to the refund transfer's mixin snapshot" do
    payment = build_refunded_payment!

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)
    refund_snapshot_id = payment.refund_transfer.snapshot_id

    assert_includes notification.url, refund_snapshot_id
    assert_includes notification.url, "https://mixin.one/snapshots/"
  end

  test "data payload mirrors the message since the notifier has no APP_CARD shape" do
    payment = build_refunded_payment!(pre_order: build_pre_order!(item: @article))

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_equal notification.message, notification.data
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @payer.messenger?

    payment = build_refunded_payment!

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "may_notify_via_mixin_bot is true for messenger recipients" do
    payment = build_refunded_payment!

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: @payer
    )

    notification = notification_for(@payer)
    assert notification.may_notify_via_mixin_bot?
  end

  test "may_notify_via_mixin_bot is false for non-messenger recipients" do
    reader_two_auth = user_authorizations(:reader_two_auth)
    reader_two_auth.update!(provider: "fennec")
    fennec_recipient = users(:reader_two)
    fennec_recipient.create_notification_setting! if fennec_recipient.notification_setting.blank?
    payment = build_refunded_payment!

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: fennec_recipient
    )

    notification = notification_for(fennec_recipient)
    assert_not notification.may_notify_via_mixin_bot?
  end

  test "deliver does not send a mixin bot message when recipient is not a messenger" do
    reader_two_auth = user_authorizations(:reader_two_auth)
    reader_two_auth.update!(provider: "fennec")
    fennec_recipient = users(:reader_two)
    fennec_recipient.create_notification_setting! if fennec_recipient.notification_setting.blank?
    payment = build_refunded_payment!

    deliver_notifier!(
      PaymentRefundedNotifier,
      record: payment,
      payment: payment,
      recipient: fennec_recipient
    )

    perform_enqueued_jobs only: Noticed::EventJob
    perform_enqueued_jobs only: DeliveryMethods::MixinBot

    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end

  private

  def build_refunded_payment!(pre_order: nil)
    trace_id = SecureRandom.uuid
    refund_snapshot_id = SecureRandom.uuid

    memo = if pre_order
      build_payment_memo(type: "BUY", article: @article, follow_id: pre_order.follow_id)
    else
      build_payment_memo(type: "BUY", article: @article)
    end

    payment = nil
    stub_notifications! do
      payment = Payment.new(
        amount: @article.price,
        memo: memo,
        raw: {
          "amount" => @article.price.to_s,
          "asset_id" => @article.asset_id,
          "memo" => memo,
          "opponent_id" => @payer.mixin_uuid,
          "snapshot_id" => SecureRandom.uuid,
          "trace_id" => trace_id
        },
        asset_id: @article.asset_id,
        snapshot_id: SecureRandom.uuid,
        trace_id: trace_id,
        payer: @payer,
        state: "refunded"
      )
      payment.define_singleton_method(:generate_order!) { }
      payment.save!(validate: false)
    end

    Transfer.create!(
      transfer_type: :payment_refund,
      source: payment,
      amount: payment.amount,
      asset_id: @article.asset_id,
      opponent_id: @payer.mixin_uuid,
      trace_id: SecureRandom.uuid,
      snapshot: { "snapshot_id" => refund_snapshot_id }
    )
    # `Transfer#snapshot_id` is a method that reads from `snapshot` JSON; the
    # notifier calls `payment.refund_transfer.snapshot_id`, so reset the
    # association cache to expose the newly-created refund transfer.
    payment.association(:refund_transfer).reset

    payment
  end

  def build_pre_order!(item:)
    with_quill_bot_stub do
      MixinPreOrder.create!(
        item: item,
        payer: @payer,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )
    end
  end
end
