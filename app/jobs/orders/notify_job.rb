# frozen_string_literal: true

class Orders::NotifyJob < ApplicationJob
  def perform(id)
    Order.find_by(id: id)&.notify
  end
end
