# frozen_string_literal: true

class PaymentCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  param :payment

  def data
    message
  end

  def message
    [t('.paid'), params[:payment].price_tag].join(' ')
  end

  def url
    format(
      '%<host>s/snapshots/%<snapshot_id>s',
      host: 'https://mixin.one',
      snapshot_id: params[:payment].snapshot_id
    )
  end
end
