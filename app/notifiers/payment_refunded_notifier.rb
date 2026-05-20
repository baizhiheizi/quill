# frozen_string_literal: true

class PaymentRefundedNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "PLAIN_TEXT"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :payment

  notification_methods do
    def data
      message
    end

    def message
      t(".refunded", item: params[:payment].pre_order&.item&.title)
    end

    def url
      format(
        "%<host>s/snapshots/%<snapshot_id>s",
        host: "https://mixin.one",
        snapshot_id: params[:payment].refund_transfer.snapshot_id
      )
    end

    def may_notify_via_mixin_bot?
      recipient_messenger?
    end
  end
end
