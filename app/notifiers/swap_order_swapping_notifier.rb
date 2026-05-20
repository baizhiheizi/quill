# frozen_string_literal: true

class SwapOrderSwappingNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "PLAIN_TEXT"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :swap_order

  notification_methods do
    def data
      message
    end

    def message
      [
        t(".swapping"),
        params[:swap_order].pay_asset&.symbol,
        "->",
        params[:swap_order].fill_asset&.symbol
      ].join(" ")
    end

    def url
      dashboard_orders_url
    end

    def may_notify_via_mixin_bot?
      recipient_messenger?
    end
  end
end
