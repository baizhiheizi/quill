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

    # Delegate to `Article.with_associations` — the shared scope covers
    # `:currency` + `:tags` + `cover_attachment: :blob` + the author avatar
    # chain consumed by `articles/_card`. Centralizing the include list at
    # the model layer keeps this controller and `Users::ArticlesController#index`
    # (and `ArticleSearchService`) byte-for-byte in sync; if the card partial
    # adds new associations, only `with_associations` needs to change.
    @pagy, @articles = pagy articles.with_associations.order(updated_at: :desc)
  end

  def show
    @tab = params[:tab] || "buy_records"
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
