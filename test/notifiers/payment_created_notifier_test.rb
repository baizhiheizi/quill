# frozen_string_literal: true

require "test_helper"

class PaymentCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @payer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@payer)
  end

  test "message uses the paid translation and includes the price tag" do
    payment = create_payment!(payer: @payer, article: @article)

    deliver_notifier!(PaymentCreatedNotifier, record: payment, payment: payment, recipient: @payer)

    assert_equal [ I18n.t("notifiers.payment_created_notifier.notification.paid"), payment.price_tag ].join(" "),
                 notification_for(@payer).message
  end

  test "url anchors to the mixin snapshot for the payment" do
    payment = create_payment!(payer: @payer, article: @article)

    deliver_notifier!(PaymentCreatedNotifier, record: payment, payment: payment, recipient: @payer)

    assert_includes notification_for(@payer).url, payment.snapshot_id
  end
end
