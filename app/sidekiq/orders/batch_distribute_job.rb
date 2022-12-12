# frozen_string_literal: true

class Orders::BatchDistributeJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  def perform
    Order.paid.map(&:distribute_async)
  end
end
