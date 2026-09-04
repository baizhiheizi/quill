# frozen_string_literal: true

class Comments::NotifySubscribersJob < ApplicationJob
  queue_as :default
  def perform(id)
    Comment.find_by(id:)&.notify_subscribers
  end
end
