# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::BaseController
    def index
      # Eager-load associations consumed by the rendered partial
      # `app/views/admin/articles/_article.html.erb`:
      #   - `:currency` → `article.price_tag` (renders the currency code)
      #   - `:tags`     → tag chips (currently not rendered in the index, but
      #                   kept for parity with `Article.with_associations`)
      #   - `author: admin_user_field_preloads` → `render "admin/users/field",
      #     user: article.author` (line 9 of the partial) → `shared/_avatar`
      #     with `thumb: true` → `user.avatar_image_thumb` → walks the
      #     ActiveStorage `:avatar_attachment.blob.variant_records` chain
      #     AND `authorization&.raw&.[]("avatar_url")` (the OAuth fallback
      #     used when no avatar is attached).
      #
      # `admin_user_field_preloads` is the canonical preload chain used by
      # `Admin::OrdersController`, `Admin::PaymentsController`,
      # `Admin::TransfersController`, and `Admin::BonusesController`. Without
      # it, each row triggers ~3 extra SELECTs (authorization + avatar
      # attachment + blob/variant). For the default pagy page of 50 articles
      # that's ~150 extra SELECTs per request.
      #
      # We inline the includes here (instead of using `Article.with_associations`,
      # which only does `includes(:currency, :tags, :author)`) because the
      # admin avatar chain is heavier than what public callers want — the
      # admin views render every row's author avatar thumbnail.
      articles =
        Article.includes(:currency, :tags, author: admin_user_field_preloads)

      articles = articles.where(author_id: params[:author_id]) if params[:author_id].present?
      articles = articles.where(collection_id: params[:collection_id]) if params[:collection_id].present?

      @locale = params[:locale] || "all"
      articles =
        case @locale
        when "all"
          articles
        when "others"
          articles.where.not(locale: %i[en zh ja])
        else
          articles.where(locale: @locale)
        end

      @state = params[:state] || "all"
      articles =
        case @state
        when "all"
          articles
        else
          articles.where(state: @state)
        end

      @order_by = params[:order_by] || "created_at_desc"
      articles =
        case @order_by
        when "published_at_desc"
          articles.order(published_at: :desc)
        when "published_at_asc"
          articles.order(published_at: :asc)
        when "created_at_desc"
          articles.order(created_at: :desc)
        when "created_at_asc"
          articles.order(updated_at: :desc)
        when "revenue_usd"
          articles.order_by_revenue_usd
        when "orders_count"
          articles.order(orders_count: :desc, created_at: :desc)
        when "comments_count"
          articles.order(comments_count: :desc, created_at: :desc)
        when "upvotes_count"
          articles.order(upvotes_count: :desc, created_at: :desc)
        when "downvotes_count"
          articles.order(downvotes_count: :desc, created_at: :desc)
        end

      @query = params[:query].to_s.strip
      articles =
        articles.ransack(
          {
            title_i_cont_all: @query,
            intro_i_cont_all: @query,
            content_i_cont_all: @query,
            uuid_eq: @query,
            id_eq: @query
          }.merge(m: "or")
        ).result

      @pagy, @articles = pagy(:countless, articles)
    end

    def show
      @tab = params[:tab] || "orders"
      @article = Article.find_by uuid: params[:uuid]
    end

    def block
      @article = Article.find_by(uuid: params[:article_uuid])
      @article.block! if @article.may_block?
    end

    def unblock
      @article = Article.find_by(uuid: params[:article_uuid])
      @article.unblock! if @article.may_unblock?
    end
  end
end
