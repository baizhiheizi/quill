# frozen_string_literal: true

class TransferProcessedNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "APP_CARD"
    config.bot = "RevenueBot"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :transfer

  notification_methods do
    def transfer_type
      case params[:transfer].transfer_type.to_sym
      when :author_revenue
        t(".author_revenue")
      when :reader_revenue
        t(".reader_revenue")
      when :payment_refund
        t(".payment_refund")
      when :bonus
        t(".bonus")
      end
    end

    def data
      {
        icon_url:,
        title: format("%.8f", params[:transfer].amount),
        description: params[:transfer].currency.symbol,
        action: "mixin://snapshots?trace=#{params[:transfer].trace_id}",
        shareable: false
      }
    end

    def message
      [ t(".received"), params[:transfer].price_tag, transfer_type ].join(" ")
    end

    def icon_url
      params[:transfer].currency.icon_url
    end

    def url
      format(
        "%<host>s/snapshots/%<snapshot_id>s",
        host: "https://mixin.one",
        snapshot_id: params[:transfer].snapshot_id
      )
    end

    def web_notification_enabled?
      recipient.notification_setting.transfer_processed_web
    end

    def mixin_bot_notification_enabled?
      recipient.notification_setting.transfer_processed_mixin_bot
    end

    def from_quill_bot?
      params[:transfer].wallet.blank?
    end

    def may_notify_via_mixin_bot?
      recipient_messenger? && mixin_bot_notification_enabled? && !from_quill_bot?
    end
  end
end
