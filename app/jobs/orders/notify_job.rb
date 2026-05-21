# frozen_string_literal: true

class Orders::NotifyJob < ApplicationJob
  queue_as :default
  def perform(id)
    Order.find_by(id:)&.notify
  end
end
