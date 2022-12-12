# frozen_string_literal: true

class Articles::NotifyForFirstPublishedJob
  include Sidekiq::Job
  sidekiq_options queue: :default

  def perform(id)
    Article.find_by(id: id)&.notify_for_first_published
  end
end
