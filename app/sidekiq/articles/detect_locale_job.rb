# frozen_string_literal: true

class Articles::DetectLocaleJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(uuid)
    Article.find_by(uuid: uuid)&.detect_locale
  end
end
