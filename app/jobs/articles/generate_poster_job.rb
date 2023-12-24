# frozen_string_literal: true

class Articles::GeneratePosterJob < ApplicationJob
  queue_as :low

  def perform(id)
    article = Article.find_by(id: id)
    return if article.blank?

    article.generate_poster unless article.poster.attached?
  end
end
