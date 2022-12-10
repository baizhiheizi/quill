# frozen_string_literal: true

class Collections::ArticlesController < Collections::BaseController
  def index
    @pagy, @articles = pagy @collection.articles.published.order(published_at: :desc), items: 5
  end
end
