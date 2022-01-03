# frozen_string_literal: true

class ArticleNotifyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id)
    Article.find_by(id: id)&.notify
  end
end
