# frozen_string_literal: true

class ArticleSearchService
  def initialize(params)
    @query = params[:query]
    @tag = params[:tag]
    @filter = params[:filter]
    @time_range = params[:time_range]
    @articles = Article.published
  end

  def call
    query
      .filter
      .select_in_time_range

    @articles
  end

  def query
    q_ransack =
      if @tag.present?
        q = @tag.to_s.strip
        { tags_name_i_cont_all: q }
      else
        q = @query.to_s.strip
        { title_i_cont: q, intro_i_cont: q, author_name_i_cont: q, tags_name_i_cont: q }
      end

    @articles = @articles.ransack(q_ransack.merge(m: 'or')).result

    self
  end

  def filter
    @articles =
      case @filter
      when 'lately'
        @articles.order(published_at: :desc)
      when 'revenue'
        @articles.order_by_revenue_usd
      when 'subscribed'
        @articles.where(author_id: current_user&.subscribe_user_ids).order(published_at: :desc)
      else
        @articles.order_by_popularity
      end

    self
  end

  def select_in_time_range
    @articles =
      case @time_range
      when 'week'
        @articles.where(published_at: (Time.current - 1.week)...)
      when 'month'
        @articles.where(published_at: (Time.current - 1.month)...)
      when 'year'
        @articles.where(published_at: (Time.current - 1.year)...)
      else
        @articles
      end

    self
  end
end
