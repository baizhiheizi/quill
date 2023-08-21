# frozen_string_literal: true

class PaymentRefundedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :payment

  def data
    message
  end

  def message
    t('.refunded', item: params[:payment].pre_order&.item&.title)
  end

  def url
    format(
      '%<host>s/snapshots/%<snapshot_id>s',
      host: 'https://mixin.one',
      snapshot_id: params[:payment].refund_transfer.snapshot_id
    )
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
