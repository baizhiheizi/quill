# frozen_string_literal: true

class ArticleGeneratePosterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(id)
    article = Article.find_by(id: id)
    return if article.blank?

    article.generate_poster unless article.poster.attached?
  end
end
