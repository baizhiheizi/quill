# frozen_string_literal: true

class TransferProcessedNotifier < ApplicationNotifier
  notifies :transfer_processed

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

    # Deep-links into Mixin, so it carries an extra key the other cards omit.
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

    def should_notify?
      !from_quill_bot?
    end

    def from_quill_bot?
      params[:transfer].wallet.blank?
    end
  end
end
