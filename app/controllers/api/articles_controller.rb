# frozen_string_literal: true

class API::ArticlesController < API::BaseController
  before_action :authenticate_user!, only: [:create]

  def index
    order = params[:order] == 'asc' ? :asc : :desc
    limit = params[:limit] || 20
    limit = 100 if limit.to_i > 100

    @articles =
      if current_user
        current_user.articles
      else
        Article.only_published
      end
    @articles = @articles.includes(:author, :tags, :currency).order(created_at: order).limit(limit)
    @articles = @articles.where(created_at: Time.zone.parse(params[:offset])...) if params[:offset].present?
  end

  def show
    @article = Article.find_by!(uuid: params[:uuid])

    return if @article.published?

    render_not_found unless @article.authorized? current_user
  end

  def create
    article = current_user.articles.new(article_params)
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
