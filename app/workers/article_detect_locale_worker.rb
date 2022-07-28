# frozen_string_literal: true

class ArticleDetectLocaleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(uuid)
    Article.find_by(uuid: uuid)&.detect_locale
  end
end
