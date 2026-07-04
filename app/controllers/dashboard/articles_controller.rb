# frozen_string_literal: true

class Dashboard::ArticlesController < Dashboard::BaseController
  def index
    @tab = params[:tab] || "drafted"
    @active_section = @tab == "bought" ? :read : :write

    articles =
      case @tab
      when "drafted"
        current_user.articles.drafted
      when "hidden"
        current_user.articles.hidden
      when "published"
        current_user.articles.published
      when "bought"
        current_user.bought_articles
      end

    # Eager-load associations consumed by the rendered partials:
    #   - `:currency` → `article.currency.icon_url`, `article.price_tag`, `article.price_usd`
    #     (in `_published_article`, `_hidden_article`, and `articles/_card`)
    #   - `:author`  → `user_article_path(article.author, ...)` and the author block in `articles/_card`
    #   - `cover_attachment: :blob` → `article.cover.attached?` + `article.cover_url`
    #     (Rails 6+ ActiveStorage nested preload — answers `attached?` from the cached
    #     `Attachment` row and resolves `cover.key` from the preloaded `Blob`)
    #   - `:tags`    → `article.tags.first(2)` in `articles/_card` (bought tab)
    #
    # Without these includes, each row triggers ~4–6 SELECTs. For an author with N
    # articles on the dashboard tabs, the action runs **~(4–6)N + 1** SELECTs per page
    # load (more for the `bought` tab since `_card` also touches `:author` and `:tags`).
    @pagy, @articles = pagy articles.includes(:author, :currency, :tags, cover_attachment: :blob).order(updated_at: :desc)
  end

  def show
    @tab = params[:tab] || "buy_records"
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
