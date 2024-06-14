# frozen_string_literal: true

class Orders::CacheHistoryTickerJob < ApplicationJob
  queue_as :low

  def perform(id)
    order = Order.find_by(id:)
    return if order.blank?

    order.cache_history_ticker
  end
end
