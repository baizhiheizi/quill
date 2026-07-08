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
    @article = Article.with_show_associations.without_drafted.find_by(uuid: params[:uuid])
    return render_not_found_page if @article.blank?

    authorize @article, :show?

    @page_title = "#{@article.title} - #{@article.author.name}"
    @page_image = @article.thumb_url
    @page_description = @article.intro

    # Prime the action_store / order-count / readers queries so the
    # partials (`_votes`, `_floating_bar`, `_buyers`) read preloaded values
    # instead of firing a SELECT per call. See the helper methods below
    # for the per-relation breakdown. The random-readers sample is
    # skipped when there are no readers — there's nothing to render in
    # that branch of the partial.
    preloaded_upvoted_article_ids
    preloaded_downvoted_article_ids
    preloaded_buy_orders_count
    preloaded_reward_orders_count
    preloaded_readers_count
    preloaded_random_readers

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

  # Set of `Article#id`s that `current_user` has upvoted. Replaces the
  # `user.upvote_article?(article)` calls in `articles/_votes.html.erb` and
  # `articles/_floating_bar.html.erb` — that action_store helper does
  # `Action.find_by(...).present?` which is 1 SELECT per call, and each of
  # those partials consults it twice (state-check + button target), so the
  # show page fires 4 SELECTs of this kind before any other work. With this
  # prime we collapse all upvoted-id lookups for the show view to a single
  # SELECT.
  #
  # `upvote_article_actions` is the action_store-generated relation
  # (`has_many :upvote_article_actions` → `Action.where(...)`); `pluck` keeps
  # the result as a flat Array of ids so we never load the full Action
  # rows. `.to_set` makes the per-article include? check O(1).
  def preloaded_upvoted_article_ids
    return @preloaded_upvoted_article_ids if defined?(@preloaded_upvoted_article_ids)

    @preloaded_upvoted_article_ids =
      if current_user
        current_user.upvote_article_actions.pluck(:target_id).to_set
      else
        Set.new
      end
  end

  # See `preloaded_upvoted_article_ids` — same shape for the downvote side.
  def preloaded_downvoted_article_ids
    return @preloaded_downvoted_article_ids if defined?(@preloaded_downvoted_article_ids)

    @preloaded_downvoted_article_ids =
      if current_user
        current_user.downvote_article_actions.pluck(:target_id).to_set
      else
        Set.new
      end
  end

  # Combined buy/reward order count for `@article` in a single grouped
  # query. Replaces `article.buy_orders.count` + `article.reward_orders.count`
  # in `articles/_buyers.html.erb` (2 SELECTs → 1).
  #
  # Returns 0 (not nil) when no matching orders exist so the view can do
  # `>= 0` arithmetic without nil guards. The grouped query runs at most
  # once per request — both `preloaded_buy_orders_count` and
  # `preloaded_reward_orders_count` consult the same memoized
  # `@preloaded_buy_reward_counts` Hash.
  def preloaded_buy_orders_count
    preloaded_buy_reward_counts
    @buy_orders_count
  end

  # See `preloaded_buy_orders_count` — same grouped query, reward side.
  def preloaded_reward_orders_count
    preloaded_buy_reward_counts
    @reward_orders_count
  end

  # Memoized grouped buy/reward counts for `@article`. Both helper methods
  # above call this; the actual SELECT runs at most once per request.
  def preloaded_buy_reward_counts
    return @preloaded_buy_reward_counts if defined?(@preloaded_buy_reward_counts)

    @preloaded_buy_reward_counts = Order
      .where(item_type: "Article", item_id: @article.id, order_type: %w[buy_article reward_article])
      .group(:order_type)
      .count

    @buy_orders_count = @preloaded_buy_reward_counts["buy_article"] || 0
    @reward_orders_count = @preloaded_buy_reward_counts["reward_article"] || 0
  end

  # Single SELECT that returns the distinct reader count. Replaces
  # `article.readers.exists?` + `article.readers.count` in
  # `articles/_buyers.html.erb` (2 SELECTs → 1).
  def preloaded_readers_count
    return @readers_count if defined?(@readers_count)

    @readers_count = @article.readers.distinct.count
  end

  # Bounded sample of readers with the avatar chain preloaded. Replaces
  # `article.random_readers(24)` in `articles/_buyers.html.erb`. The
  # `shared/_avatar` partial called inside the loop walks the
  # `:avatar_attachment → :blob → :variant_records` chain, so without the
  # preload each of the 24 readers would fire ~3 SELECTs to load their
  # avatar thumbnails.
  def preloaded_random_readers
    return @random_readers if defined?(@random_readers)

    sampled_buyer_ids = @article
      .orders
      .select(:buyer_id)
      .group(:buyer_id)
      .order(Arel.sql("RANDOM()"))
      .limit(24)

    # The shared `dashboard_user_field_preloads` / `admin_user_field_preloads`
    # chains (see `Dashboard::BaseController`, `Admin::BaseController`) are
    # admin-specific. The public avatar chain is the same shape, but we
    # inline it here so the public show page doesn't need to depend on a
    # private controller helper from a different namespace.
    @random_readers = User
      .where(id: sampled_buyer_ids)
      .includes(
        :authorization,
        {
          avatar_attachment: {
            blob: {
              variant_records: { image_attachment: :blob },
              preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } }
            }
          }
        }
      )
      .to_a
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
