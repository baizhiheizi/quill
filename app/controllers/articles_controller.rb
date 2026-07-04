# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update preview]
  before_action :load_article, only: %i[edit update preview]
  layout :public_or_editor_layout

  def index
    @query = params[:query]
    @filter = params[:filter] || "default"
    @time_range = params[:time_range]
    @time_range ||= "week" if @filter == "revenue"
    @tag = Tag.find_by name: params[:tag].to_s.strip

    articles = ArticleSearchService.call(params.merge(current_user:))

    @pagy, @articles = pagy(:countless, articles.with_attached_cover)
    @active_page = "home"

    respond_to do |format|
      format.html
      format.turbo_stream
      format.rss do
        articles = ArticleSearchService.call(filter: "lately")

        @pagy, @articles = pagy(:countless, articles.with_attached_cover)
        render layout: false
      end
    end
  end

  def show
    @article = Article.with_associations.without_drafted.find_by(uuid: params[:uuid])
    return render_not_found_page if @article.blank?

    authorize @article, :show?

    @page_title = "#{@article.title} - #{@article.author.name}"
    @page_image = @article.thumb_url
    @page_description = @article.intro

    impressionist @article, @article.authorized?(current_user) ? "full" : "partial"
  end

  def new
    collection = current_user.collections.find_by(uuid: params[:collection_id])
    @article = current_user.articles.new(collection: collection)
    assign_new_article_defaults!(@article)
  end

  def edit
  end

  def create
    @article = current_user.articles.new create_article_params

    saved = false
    ActiveRecord::Base.transaction do
      saved = @article.save
      CreateTagService.call(@article, tag_names_param) if saved
    end

    respond_to do |format|
      if saved
        @article.reload
        format.html { redirect_to edit_article_path(@article.uuid) }
        format.json do
          render json: {
            uuid: @article.uuid,
            edit_path: edit_article_path(@article.uuid),
            lock_version: @article.lock_version
          }
        end
        format.turbo_stream { render :create }
      else
        format.html { render :new, status: :unprocessable_entity, layout: "editor" }
        format.json { render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  def update
    ActiveRecord::Base.transaction do
      CreateTagService.call(@article, tag_names_param) if params.dig(:article, :tag_names)
      @article.update! update_article_params
    end

    respond_to do |format|
      format.html { redirect_to edit_article_path(@article.uuid) }
      format.turbo_stream
      format.json do
        render json: {
          uuid: @article.uuid,
          lock_version: @article.lock_version,
          updated_at: @article.updated_at.iso8601
        }
      end
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity, layout: "editor" }
      format.turbo_stream { render status: :unprocessable_entity }
      format.json { render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity }
    end
  rescue ActiveRecord::StaleObjectError
    @article.reload
    respond_to do |format|
      format.turbo_stream { render :update_conflict, status: :conflict }
      format.json do
        render json: {
          conflict: true,
          lock_version: @article.lock_version,
          errors: [ I18n.t("articles.save_conflict") ]
        }, status: :conflict
      end
    end
  end

  def preview
    @preview_user = nil
  end

  def share
    @article = Article.published.find_by uuid: params[:article_uuid]
    if @article.present?
      impressionist @article, "share"
    else
      render_not_found_page
    end
  end

  private

  def public_or_editor_layout
    action_name.in?(%w[new edit preview]) ? "editor" : "public"
  end

  def create_article_params
    params
      .require(:article)
      .permit(
        :title,
        :content,
        :asset_id,
        :intro,
        :free_content_ratio,
        :author_revenue_ratio,
        :readers_revenue_ratio,
        :references_revenue_ratio,
        :price,
        :cover,
        :collection_id,
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
      free_content_ratio
      lock_version
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

  def tag_names_param
    Array(params.dig(:article, :tag_names)).compact_blank
  end

  def assign_new_article_defaults!(article)
    return if article.blank?

    article.uuid = SecureRandom.uuid if article.uuid.blank?
    article.asset_id = Currency::BTC_ASSET_ID if article.asset_id.blank?

    default_currency = article.currency || Currency.btc
    return if article.price.present? || default_currency.blank?

    article.price = default_currency.minimal_price_amount
  end

  def load_article
    article_uuid = params[:uuid].presence || params[:article_uuid]
    @article = current_user.articles.find_by uuid: article_uuid
    render_not_found_page if @article.blank?
  end
end
