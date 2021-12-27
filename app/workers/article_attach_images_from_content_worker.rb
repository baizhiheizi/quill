# frozen_string_literal: true

class ArticleAttachImagesFromContentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(uuid)
    Article.find_by(uuid: uuid)&.attach_images_from_content
  end
end
