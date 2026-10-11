# frozen_string_literal: true

module Users
  class ArticlesController < Users::BaseController
    def index
      # Only `published` and `bought` are real tabs. Any other `tab` value
      # (typo, stale link, probe) used to leave `articles` nil and blow up on
      # `.with_associations` below (issue #2105) — fall back to `published`.
      @tab = params[:tab].presence_in(%w[published bought]) || "published"
      articles =
        case @tab
        when "bought"
          @user.bought_articles.published
        else
          @user.articles.published
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
