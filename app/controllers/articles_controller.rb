# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :authenticate_user!, only: %i[new edit update update_content]
  before_action :load_article, only: %i[edit update]
  layout 'editor', only: %i[new edit]

  def index
    @query = params[:query]
    @filter = params[:filter] || 'default'
    @time_range = params[:time_range]
    @time_range ||= 'week' if @filter == 'revenue'
    @tag = Tag.find_by name: params[:tag].to_s.strip

    articles = ArticleSearchService.call(params.merge(current_user: current_user, locale: current_locale))

    @pagy, @articles = pagy_countless articles.with_attached_cover
    @active_page = 'home'

    respond_to do |format|
      format.html
      format.turbo_stream
      format.rss do
        render layout: false
      end
    end
  end

  def show
    @article = Article.without_drafted.fetch_by_uniq_keys uuid: params[:uuid]

    if @article&.authorized?(current_user) || @article&.may_buy_by?(current_user)
      @page_title = "#{@article.title} - #{@article.author.name}"
      @page_image = @article.thumb_url
      @page_description = @article.intro

      impressionist @article, @article.authorized?(current_user) ? 'full' : 'partial'
    else
      redirect_back fallback_location: root_path
    end
  end

  def new
    collection = current_user.collections.find_by uuid: params[:collection_id]
    @article = current_user.articles.new collection: collection
  end

  def edit
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
    @article.assign_attributes params.require(:article).permit(:title, :content)
    @article.content = @article.content.gsub(/!\[[^\]]*\]\((.*?)\s*("(?:.*[^"])")?\s*\)(\\n)*/) { |m| "#{m.strip}\n" }
    @article.save
  end

  def share
    @article = Article.published.find_by uuid: params[:article_uuid]
    if @article.present?
      impressionist @article, 'share'
    else
      redirect_back fallback_location: root_path
    end
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
        :readers_revenue_ratio,
        :references_revenue_ratio,
        :price,
        :cover,
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
      cover
    ]

    permitted.push(:price) if !@article.published_at? || (!@article.free? && params[:article][:price].to_d.positive?)
    if @article.published_at?
      permitted.push(:collection_id) if @article.collection_revenue_ratio.zero?
    else
      permitted.push(
        :collection_id,
        :author_revenue_ratio,
        :readers_revenue_ratio,
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
