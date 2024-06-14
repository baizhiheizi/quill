# frozen_string_literal: true

class Articles::NotifyForFirstPublishedJob < ApplicationJob
  def perform(id)
    Article.find_by(id:)&.notify_for_first_published
  end
end
