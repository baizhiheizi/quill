# frozen_string_literal: true

class Orders::BatchDistributeJob < ApplicationJob
  queue_as :low

  def perform
    Order.paid.map(&:distribute_async)
  end
end
