# frozen_string_literal: true

class Articles::NotifyForFirstPublishedJob < ApplicationJob
  queue_as :default
  def perform(id)
    Article.find_by(id:)&.notify_for_first_published
  end
end
