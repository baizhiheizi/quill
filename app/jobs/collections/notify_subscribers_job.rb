# frozen_string_literal: true

class Collections::NotifySubscribersJob < ApplicationJob
  queue_as :default
  def perform(id)
    Collection.find_by(id:)&.notify_subscribers
  end
end
