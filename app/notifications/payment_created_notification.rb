# frozen_string_literal: true

class PaymentCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  before_mixin_bot :set_locale

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

  def set_locale
    I18n.locale = recipient.locale if recipient.locale.present?
  end
end
