# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :authenticate_user!, only: %i[new edit update]
  before_action :load_article, only: %i[edit update]
  layout 'editor', only: %i[new edit]

  def index
    @query = params[:query]
    @filter = params[:filter] || 'default'
    @time_range = params[:time_range]
    @time_range ||= 'month' if @filter == 'revenue'
    @tag = Tag.find_by name: params[:tag].to_s.strip

    articles = ArticleSearchService.call(params, current_user, current_locale)

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
  end

  def edit
  end

  def show
    @article = Article.without_drafted.find_by uuid: params[:uuid]

    if @article&.authorized?(current_user) || @article&.may_buy_by?(current_user)
      @page_title = "#{@article.title} - #{@article.author.name}"
      @page_description = @article.intro
      @page_image = @article.author.avatar
    else
      redirect_back fallback_location: root_path
    end
  end

  def create
    @article = current_user.articles.new create_article_params

    if @article.save
      redirect_to edit_article_path(@article.uuid)
    else
      render :new, status: :unprocessable_entity, layout: 'editor'
    end
  end

  def update
    CreateTag.call(@article, params[:article][:tag_names] || [])
    @article.update update_article_params
  end

  def update_content
    @article = current_user.articles.find_by uuid: params[:article_uuid]
    @article.update params.require(:article).permit(:title, :content)

    render json: {
      content: @article.reload.content,
      updated_at: @article.updated_at
    }
  end

  def share
    @article = Article.published.find_by uuid: params[:article_uuid]
  end

  def preview
  end

  private

  def create_article_params
    params
      .require(:article)
      .permit(
        :title,
        :content,
        :asset_id,
        :intro,
        :author_revenue_ratio,
        :references_revenue_ratio,
        :price,
        article_references_attributes: %i[
          id
          reference_type
          reference_id
          revenue_ratio
          _destroy
        ]
      )
  end

  def update_article_params
    permitted = %i[
      title
      content
      intro
    ]

    permitted.push(:price) if !@article.published_at? || (!@article.free? && params[:article][:price].to_d.positive?)
    unless @article.published_at?
      permitted.push(
        :author_revenue_ratio,
        :references_revenue_ratio,
        :asset_id,
        { article_references_attributes: %i[
          id
          reference_type
          reference_id
          revenue_ratio
          _destroy
        ] }
      )
    end

    params
      .require(:article)
      .permit(permitted)
  end

  def load_article
    @article = current_user.articles.find_by uuid: params[:uuid]
    redirect_back fallback_location: root_path if @article.blank?
  end
end
