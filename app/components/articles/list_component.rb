# frozen_string_literal: true

class Articles::ListComponent < ApplicationComponent
  def initialize(articles: [], pagy: nil)
    super

    @articles = articles.presence || ArticleSearchService.call
    @pagy = pagy
  end
end
