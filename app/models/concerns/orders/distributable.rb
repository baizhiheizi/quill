# frozen_string_literal: true

module Orders::Distributable
  extend ActiveSupport::Concern

  def distribute_async
    Orders::DistributeJob.perform_later trace_id
  end

  def distribute!
    Orders::DistributeService.call(self)
  end

  def early_orders
    @early_orders ||=
      item
      .orders
      .where(order_type: %i[buy_article reward_article])
      .where("id < ? and created_at < ?", id, created_at)
      .order(created_at: :desc)
  end

  def early_orders_with_the_same_currency
    @early_orders_with_the_same_currency ||=
      early_orders.where.not(asset_id:).blank?
  end

  def collect_early_readers
    readers = {}
    early_orders.each do |_order|
      readers[_order.buyer.mixin_uuid] ||= []
      readers[_order.buyer.mixin_uuid].push _order.trace_id
    end

    readers
  end
end
