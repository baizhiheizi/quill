# frozen_string_literal: true

require "test_helper"

class TransferProcessedNotifierTest < ActiveSupport::TestCase
  setup do
    @recipient = users(:author)
    ensure_notification_setting!(@recipient)
    @transfer = create_transfer!(recipient: @recipient)
  end

  test "message joins the received translation, price tag, and transfer type" do
    deliver_notifier!(TransferProcessedNotifier, record: @transfer, transfer: @transfer, recipient: @recipient)

    notification = notification_for(@recipient)

    assert_includes notification.message,
                    I18n.t("notifiers.transfer_processed_notifier.notification.received")
    assert_includes notification.message, @transfer.price_tag
    assert_includes notification.message,
                    I18n.t("notifiers.transfer_processed_notifier.notification.author_revenue")
  end

  test "transfer_type label switches to reader_revenue for reader_revenue transfers" do
    @transfer.update! transfer_type: :reader_revenue

    deliver_notifier!(TransferProcessedNotifier, record: @transfer, transfer: @transfer, recipient: @recipient)

    notification = notification_for(@recipient)

    assert_includes notification.message,
                    I18n.t("notifiers.transfer_processed_notifier.notification.reader_revenue")
    assert_not_includes notification.message,
                        I18n.t("notifiers.transfer_processed_notifier.notification.author_revenue")
  end

  test "transfer_type label switches to payment_refund for refund transfers" do
    @transfer.update! transfer_type: :payment_refund

    deliver_notifier!(TransferProcessedNotifier, record: @transfer, transfer: @transfer, recipient: @recipient)

    assert_includes notification_for(@recipient).message,
                    I18n.t("notifiers.transfer_processed_notifier.notification.payment_refund")
  end

  test "url anchors to the mixin snapshot" do
    deliver_notifier!(TransferProcessedNotifier, record: @transfer, transfer: @transfer, recipient: @recipient)

    notification = notification_for(@recipient)

    assert_includes notification.url, "https://mixin.one/snapshots/"
    assert_includes notification.url, @transfer.snapshot_id
  end

  test "data payload titles the amount, describes the currency, and deep-links the snapshot" do
    deliver_notifier!(TransferProcessedNotifier, record: @transfer, transfer: @transfer, recipient: @recipient)

    payload = notification_for(@recipient).data

    assert_equal format("%.8f", @transfer.amount), payload[:title]
    assert_equal @transfer.currency.symbol, payload[:description]
    assert_equal "mixin://snapshots?trace=#{@transfer.trace_id}", payload[:action]
    assert_equal false, payload[:shareable]
    assert_equal @transfer.currency.icon_url, payload[:icon_url]
  end

  test "a transfer paid out by QuillBot is not delivered again to the messenger" do
    @transfer.update! wallet: nil

    deliver_notifier!(TransferProcessedNotifier, record: @transfer, transfer: @transfer, recipient: @recipient)

    assert_not notification_for(@recipient).may_notify_via_mixin_bot?
  end
end
