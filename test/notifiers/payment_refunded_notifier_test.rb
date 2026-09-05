# frozen_string_literal: true

require "test_helper"

class PaymentRefundedNotifierTest < ActiveSupport::TestCase
  setup do
    @payer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@payer)
    @payment = create_refunded_payment!(payer: @payer, article: @article)
  end

  test "message uses the refunded translation with the pre-order item title" do
    pre_order = build_pre_order!(item: @article)
    payment = create_refunded_payment!(payer: @payer, article: @article, pre_order: pre_order)

    deliver_notifier!(PaymentRefundedNotifier, record: payment, payment: payment, recipient: @payer)

    assert_equal I18n.t("notifiers.payment_refunded_notifier.notification.refunded", item: @article.title),
                 notification_for(@payer).message
  end

  test "message gracefully handles payments without a pre-order" do
    deliver_notifier!(PaymentRefundedNotifier, record: @payment, payment: @payment, recipient: @payer)

    assert_equal I18n.t("notifiers.payment_refunded_notifier.notification.refunded", item: nil),
                 notification_for(@payer).message
  end

  test "url anchors to the refund transfer's mixin snapshot" do
    deliver_notifier!(PaymentRefundedNotifier, record: @payment, payment: @payment, recipient: @payer)

    assert_includes notification_for(@payer).url, @payment.refund_transfer.snapshot_id
  end

  private

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
