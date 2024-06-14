# frozen_string_literal: true

class Articles::AttachImagesFromContentJob < ApplicationJob
  def perform(uuid)
    Article.find_by(uuid:)&.attach_images_from_content
  end
end
