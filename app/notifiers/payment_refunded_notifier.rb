# frozen_string_literal: true

class PaymentRefundedNotifier < ApplicationNotifier
  notifies :payment_refunded

  required_param :payment

  notification_methods do
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
  end
end
