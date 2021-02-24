# frozen_string_literal: true

class API::ArticlesController < API::BaseController
  before_action :authenticate_user!, only: [:create]

  def index
    @articles =
      if current_user
        current_user.articles
      else
        Article.only_published
      end

    query = params[:query]&.split(',')&.map(&:strip) || []
    order = params[:order] == 'asc' ? :asc : :desc
    limit = params[:limit] || 20
    limit = 100 if limit.to_i > 100

    q_ransack = { title_i_cont_any: query, intro_i_cont_any: query, tags_name_i_cont_any: query }

    @articles =
      @articles
      .ransack(q_ransack.merge(m: 'or'))
      .result(distinct: true)
      .includes(:author, :tags, :currency)
      .order(created_at: order)
      .limit(limit)

    @articles = @articles.where(created_at: Time.zone.parse(params[:offset])...) if params[:offset].present?
  end

  def show
    @article = Article.find_by!(uuid: params[:uuid])

    return if @article.published?

    render_not_found unless @article.authorized? current_user
  end

  def create
    article = current_user.articles.new(article_params.merge(source: current_access_token.value))

    if article.save
      CreateTag.call(article, params[:tag_names] || [])
      render_created({ uuid: article.uuid })
    else
      render_unprocessable_entity article.errors.full_messages
    end
  end

  private

  def article_params
    params.require(:article).permit(:title, :intro, :content, :price, :asset_id, :state)
  end
end
