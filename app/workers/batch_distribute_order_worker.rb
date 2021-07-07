# frozen_string_literal: true

class BatchDistributeOrderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform
    Order.paid.map(&:distribute_async)
  end
end
