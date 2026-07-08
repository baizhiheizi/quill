# frozen_string_literal: true

class Orders::BatchDistributeJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 100

  def perform
    # Iterate in bounded batches so a re-scan under the blanket ApplicationJob
    # retry never re-enqueues the whole backlog in one shot. Isolate per-order
    # enqueue failures so one bad record can't abort the sweep for every other
    # paid order; each order still dispatches its own Orders::DistributeJob,
    # which is row-locked via DistributeService.
    Order.paid.find_in_batches(batch_size: BATCH_SIZE) do |orders|
      orders.each do |order|
        order.distribute_async
      rescue => e
        Rails.logger.error "Orders::BatchDistributeJob enqueue failed for order #{order.id}: #{e.class} #{e.message}"
        Rails.error.report(e, handled: true, severity: :warning,
                           context: { job: self.class.name, order_id: order.id })
      end
    end
  end
end
