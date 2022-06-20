# frozen_string_literal: true

class DistributeOrderWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :default, retry: true

  sidekiq_throttle(
    concurrency: { limit: 1, key_suffix: ->(trace_id) { trace_id } }
  )

  def perform(trace_id)
    order = Order.find_by trace_id: trace_id
    return if order.blank?

    order.distribute!
  end
end
