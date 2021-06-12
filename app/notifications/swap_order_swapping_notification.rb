# frozen_string_literal: true

class SwapOrderSwappingNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

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
    format(
      '%<host>s/dashboard/orders',
      host: Settings.host
    )
  end
end
