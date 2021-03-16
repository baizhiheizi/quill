# frozen_string_literal: true

class TransferProcessedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :mixin_bot_notification_enabled?

  param :transfer

  def transfer_type
    case params[:transfer].transfer_type.to_sym
    when :author_revenue
      t('.author_revenue')
    when :reader_revenue
      t('.reader_revenue')
    when :payment_refund
      t('.payment_refund')
    when :bonus
      t('.bonus')
    when :swap_change
      t('.swap_change')
    when :swap_refund
      t('.swap_refund')
    end
  end

  def data
    {
      icon_url: params[:transfer].currency.icon_url,
      title: format('%.8f', params[:transfer].amount),
      description: params[:transfer].currency.symbol,
      action: "mixin://snapshots?trace=#{params[:transfer].trace_id}"
    }
  end

  def message
    [t('.received'), params[:transfer].price_tag, transfer_type].join(' ')
  end

  def url
    format(
      '%<host>s/snapshots/%<snapshot_id>s',
      host: 'https://mixin.one',
      snapshot_id: params[:transfer].snapshot_id
    )
  end

  def web_notification_enabled?
    recipient.notification_setting.transfer_processed_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.transfer_processed_mixin_bot
  end
end
