# frozen_string_literal: true

module Users
  class ArticlesController < Users::BaseController
    def index
      @tab = params[:tab] || "published"
      articles =
        case @tab
        when "published"
          @user.articles.published
        when "bought"
          @user.bought_articles.published
        end

      # Delegate to `Article.with_associations` — the shared scope covers
      # `:currency` + `:tags` + `cover_attachment: :blob` + the author avatar
      # chain consumed by `articles/_card`. Same scope as
      # `Dashboard::ArticlesController#index` and `ArticleSearchService` —
      # single source of truth at the model layer.
      @pagy, @articles = pagy(:countless, articles.with_associations.order(published_at: :desc))
    end
  end
end
