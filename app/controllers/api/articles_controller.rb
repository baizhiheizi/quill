# frozen_string_literal: true

class API::ArticlesController < API::BaseController
  QUERY_LENGTH_LIMIT = 64

  before_action :authenticate_user!, only: [ :create ]

  def index
    @articles =
      if params[:author_id].present?
        author = User.find_by(mixin_uuid: params[:author_id])
        raise ActiveRecord::RecordNotFound && return if author.blank?

        author.articles.only_published
      elsif current_user
        current_user.articles
      else
        Article.only_published
      end

    # Cap the query string and each comma-separated term so a long `query`
    # param can't bloat the ILIKE pattern into an expensive seq-scan. Pairs
    # with the pg_trgm GIN indexes (see
    # db/migrate/*_add_pg_trgm_indexes_for_search.rb).
    query =
      params[:query].to_s.first(QUERY_LENGTH_LIMIT).split(",").map { |term|
        term.strip.first(QUERY_LENGTH_LIMIT)
      }.reject(&:blank?)
    limit = params[:limit] || 20
    limit = 100 if limit.to_i > 100
    order = params[:order]&.to_sym
    q_ransack = { title_i_cont_any: query, intro_i_cont_any: query, tags_name_i_cont_any: query }

    # Eager-load the author avatar chain consumed by
    # `api/articles/index.json.jbuilder` (`article.author.avatar_image_url`
    # walks `avatar_attachment → blob` plus the `authorization` fallback).
    # Closes a per-row N+1 that scales with the `limit` cap.
    @articles =
      @articles
      .ransack(q_ransack.merge(m: "or"))
      .result(distinct: true)
      .includes(:tags, :currency, author: User::AVATAR_PRELOADS)
      .limit(limit)

    @articles =
      case order
      when :asc
        @articles.order(created_at: :asc)
      when :desc
        @articles.order(created_at: :desc)
      else
        @articles.order_by_popularity
      end

    return if params[:offset].blank?

    @articles =
      if /^\d+$/.match? params[:offset]
        @articles.offset(params[:offset].to_i)
      elsif order == :asc
        @articles.where(created_at: Time.zone.parse(params[:offset])...)
      elsif order == :desc
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

  def article_params
    params.require(:article).permit(:title, :intro, :content, :price, :asset_id)
  end
end
