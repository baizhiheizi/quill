# frozen_string_literal: true

class DistributeOrderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(trace_id)
    order = Order.find_by trace_id: trace_id
    return if order.blank?

    order.distribute!
  end
end
