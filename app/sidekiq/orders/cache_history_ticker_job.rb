# frozen_string_literal: true

class Orders::CacheHistoryTickerJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: true

  def perform(id)
    order = Order.find_by id: id
    return if order.blank?

    order.cache_history_ticker
  end
end
