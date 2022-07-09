# frozen_string_literal: true

class TransferProcessedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', bot: 'RevenueBot', if: :may_notify_via_mixin_bot?

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
      action: "mixin://snapshots?trace=#{params[:transfer].trace_id}",
      shareable: false
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

  def from_batata_bot?
    params[:transfer].wallet.blank?
  end

  def may_notify_via_mixin_bot?
    recipient_messenger? && mixin_bot_notification_enabled? && !from_batata_bot?
  end
end
