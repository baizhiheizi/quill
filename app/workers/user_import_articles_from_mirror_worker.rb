# frozen_string_literal: true

class UserImportArticlesFromMirrorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    User.find_by(id: id)&.import_articles_from_mirror
  end
end
