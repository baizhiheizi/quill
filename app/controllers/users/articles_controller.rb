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

      # Eager-load the chain consumed by `articles/_card`:
      #   - `:currency`             → `article.price_tag`
      #   - `:author`               → `article.author`, `shared/_avatar` for author block
      #   - `:tags`                 → `article.tags.first(3)`
      #   - `cover_attachment: :blob` → `article.cover.attached?` + `cover.key`
      #
      # Same shape as `Dashboard::ArticlesController#index` (PR #1815) and
      # `Users::SubscribeUsersController#index` (PR #1866) — without these,
      # each row fires ~4-6 SELECTs, so a 50-row page runs ~(4-6)N + 1.
      @pagy, @articles = pagy(:countless, articles
        .includes(:author, :currency, :tags, cover_attachment: :blob)
        .order(published_at: :desc))
    end
  end
end
