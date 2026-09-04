# frozen_string_literal: true

class API::ArticlesController < API::BaseController
  before_action :authenticate_user!, only: [ :create ]

  # `?order=asc|desc`; anything else falls back to the popularity feed.
  ORDER_KEYS = { "asc" => :oldest, "desc" => :newest }.freeze

  # The public API's frozen search contract: title, intro and tags — but not
  # the author name. Widening it would change result sets for existing
  # consumers, so this endpoint deliberately narrows `ArticleVisibility`'s
  # default field set.
  SEARCH_FIELDS = %i[title intro tags].freeze

  def index
    @articles =
      if params[:author_id].present?
        author = User.find_by(mixin_uuid: params[:author_id])
        raise ActiveRecord::RecordNotFound if author.blank?

        ArticleVisibility.for(current_user, base: author.articles.only_published)
      elsif current_user
        ArticleVisibility.for(current_user, base: current_user.articles)
      else
        ArticleVisibility.for(current_user)
      end

    order = ORDER_KEYS.fetch(params[:order], :popularity)

    # Eager-load the author avatar chain consumed by the JSON template
    # (`app/views/api/articles/index.json.jbuilder` reads
    # `article.author.avatar_image_url` per row, which loads
    # `avatar_attachment → blob` and `authorization`). Without this preload
    # each row fires 2-4 extra SELECTs (avatar_attachment + blob +
    # authorization; up to ~5 if the variant chain is touched via the
    # private `avatar_image_thumb` rescue path). For an
    # `API::ArticlesController#index` request with the default `limit: 20`
    # the action runs ~40-100 extra SELECTs; with the highest capped
    # `limit: 100` it runs up to ~400-500 extra SELECTs. With the
    # `User::AVATAR_PRELOADS` chain (byte-identical to
    # `Admin::BaseController#admin_user_field_preloads` and the same
    # chain `Article.with_associations` already uses internally for the
    # dashboard cards), the JSON render loads the chain in O(1)
    # IN-batched SELECTs regardless of page size.
    #
    # Same family as merged PRs #1802, #1815, #1829, #1830, #1833,
    # #1834, #1843, #1862, #1886, #1902, #1896, #1895.
    @articles =
      @articles
      .searching(params[:query], fields: SEARCH_FIELDS)
      .includes(:tags, :currency, author: User::AVATAR_PRELOADS)
      .limit(capped_limit)
      .ordered_by(order)

    return if params[:offset].blank?

    @articles =
      if /^\d+$/.match? params[:offset]
        @articles.offset(params[:offset].to_i)
      elsif order == :oldest
        @articles.where(created_at: Time.zone.parse(params[:offset])...)
      elsif order == :newest
        @articles.where(created_at: ...Time.zone.parse(params[:offset]))
      else
        @articles
      end
  end

  def show
    @article = Article.find_by!(uuid: params[:uuid])
    raise ActiveRecord::RecordNotFound unless ArticlePolicy.new(current_user, @article).show?
  end

  def create
    authorize Article, :create?

    article = current_user.articles.new(article_params.merge(source: current_access_token.value))

    if article.save
      CreateTagService.call(article, params[:tag_names] || [])
      article.publish! if article.may_publish?
      render_created({ uuid: article.uuid })
    else
      render_unprocessable_entity article.errors.full_messages
    end
  end

  private

  def capped_limit
    limit = params[:limit] || 20
    limit = 100 if limit.to_i > 100
    limit
  end

  def article_params
    params.require(:article).permit(:title, :intro, :content, :price, :asset_id)
  end
end
