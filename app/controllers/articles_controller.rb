# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :authenticate_user!, only: %i[edit update]
  before_action :load_article, only: %i[edit update]
  layout 'editor', only: %i[new edit]

  def index
    @query = params[:query]
    articles = ArticleSearchService.new(params).call

    @pagy, @articles = pagy_countless articles

    respond_to do |format|
      format.html
      format.turbo_stream
      format.rss do
        render layout: false
      end
    end
  end

  def new
    @article = current_user.articles.new
  end

  def edit
  end

  def show
    @article = Article.only_published.find_by uuid: params[:uuid]
    if @article.blank?
      redirect_back fallback_location: root_path, alert: t('article_not_found')
    else
      @page_title = "#{@article.title} - #{@article.author.name}"
      @page_description = @article.intro
    end
  end

  def create
    article = current_user.articles.new article_params

    if article.save
      redirect_to edit_article_path(article.uuid)
    else
      render :new
    end
  end

  def update
    CreateTag.call(@article, params[:article][:tag_names] || [])
    @article.update article_params
  end

  def preview
    render json: { html: MarkdownRenderService.new.call(params[:content]) }
  end

  private

  def article_params
    params
      .require(:article)
      .permit(
        :title,
        :content,
        :price,
        :asset_id,
        :intro,
        :author_revenue_ratio,
        :references_revenue_ratio,
        article_references_attributes: %i[
          id
          reference_type
          reference_id
          revenue_ratio
          _destroy
        ]
      )
  end

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
    redirect_back fallback_location: roo_path if @article.blank?
  end
end
