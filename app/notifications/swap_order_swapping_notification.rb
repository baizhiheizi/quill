# frozen_string_literal: true

class SwapOrderSwappingNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :swap_order

  def data
    message
  end

  def message
    [
      t('.swapping'),
      params[:swap_order].pay_asset&.symbol,
      '->',
      params[:swap_order].fill_asset&.symbol
    ].join(' ')
  end

  def url
    dashboard_orders_url
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
