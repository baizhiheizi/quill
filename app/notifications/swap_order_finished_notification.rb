# frozen_string_literal: true

class SwapOrderFinishedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :swap_order

  def data
    message
  end

  def message
    case params[:swap_order].state.to_sym
    when :completed, :refunded
      swapped_message
    when :rejected
      rejected_message
    end
  end

  def rejected_message
    t('.rejected')
  end

  def swapped_message
    [
      t('.swapped'),
      format('%.8f', params[:swap_order].funds),
      params[:swap_order].pay_asset&.symbol,
      '->',
      format('%.8f', params[:swap_order].amount),
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
