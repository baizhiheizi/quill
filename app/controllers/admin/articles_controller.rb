# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::BaseController
    def index
      articles = Article.all

      articles = articles.where(author_id: params[:author_id]) if params[:author_id].present?

      @locale = params[:locale] || 'all'
      articles =
        case @locale
        when 'all'
          articles
        when 'others'
          articles.where.not(locale: %i[en zh ja])
        else
          articles.where(locale: @locale)
        end

      @state = params[:state] || 'all'
      articles =
        case @state
        when 'all'
          articles
        else
          articles.where(state: @state)
        end

      @order_by = params[:order_by] || 'created_at_desc'
      articles =
        case @order_by
        when 'published_at_desc'
          articles.order(published_at: :desc)
        when 'published_at_asc'
          articles.order(published_at: :asc)
        when 'created_at_desc'
          articles.order(created_at: :desc)
        when 'created_at_asc'
          articles.order(updated_at: :desc)
        when 'revenue_usd'
          articles.order_by_revenue_usd
        when 'orders_count'
          articles.order(orders_count: :desc, created_at: :desc)
        when 'comments_count'
          articles.order(comments_count: :desc, created_at: :desc)
        when 'upvotes_count'
          articles.order(upvotes_count: :desc, created_at: :desc)
        when 'downvotes_count'
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
          }.merge(m: 'or')
        ).result

      @pagy, @articles = pagy_countless articles
    end

    def show
      @tab = params[:tab] || 'orders'
      @article = Article.find_by uuid: params[:uuid]
    end
  end
end
