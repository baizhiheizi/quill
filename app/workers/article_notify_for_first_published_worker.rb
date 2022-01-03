# frozen_string_literal: true

class ArticleNotifyForFirstPublishedWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id)
    Article.find_by(id: id)&.notify_for_first_published
  end
end
