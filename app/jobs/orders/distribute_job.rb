# frozen_string_literal: true

class Orders::DistributeJob < ApplicationJob
  def perform(trace_id)
    order = Order.find_by(trace_id:)
    return if order.blank?

    order.distribute!
  end
end
