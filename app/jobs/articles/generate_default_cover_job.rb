# frozen_string_literal: true

class Articles::GenerateDefaultCoverJob < ApplicationJob
  queue_as :low

  def perform(id)
    article = Article.find_by(id:)
    return if article.blank?
    return if article.cover.attached?

    article.generate_default_cover
  end
end
