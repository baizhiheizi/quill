# frozen_string_literal: true

class Orders::UpdateCacheJob < ApplicationJob
  def perform(id)
    Order.find_by(id:)&.update_cache
  end
end
