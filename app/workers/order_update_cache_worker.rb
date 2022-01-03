# frozen_string_literal: true

class OrderUpdateCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    Order.find_by(id: id)&.update_cache
  end
end
