# frozen_string_literal: true

class Dashboard::ArticlesController < Dashboard::BaseController
  def index
    # Only these four are real tabs. Any other `tab` value (typo, stale
    # link, probe) used to leave the scope nil and blow up on
    # `.with_associations` below — the same bug #2105 fixed in
    # `Users::ArticlesController#index`.
    @tab = params[:tab].presence_in(%w[drafted hidden published bought]) || "drafted"
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
    # Same allow-list policy as `#index`: only the four real sub-tabs are
    # accepted, anything else falls back to the default panel.
    @tab = params[:tab].presence_in(%w[buy_records reward_records cite_records comment_records]) || "buy_records"
    @article = current_user.articles.find_by uuid: params[:uuid]
  end
end
