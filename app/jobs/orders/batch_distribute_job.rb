# frozen_string_literal: true

class Orders::BatchDistributeJob < ApplicationJob
  queue_as :low

  def perform
    Order.paid.find_each(&:distribute_async)
  end
end
