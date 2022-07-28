# frozen_string_literal: true

class ArticleSearchService
  def initialize(params, current_user = nil, locale = nil)
    @query = params[:query]
    @tag = params[:tag]
    @filter = params[:filter]
    @time_range = params[:time_range]
    @current_user = current_user
    @articles = Article.published
    @locale = locale || current_user&.locale || I18n.default_locale
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    query
      .filter_block_authors
      .filter_block_by_authors
      .localize
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
        {
          title_i_cont: q,
          intro_i_cont: q,
          author_name_i_cont: q,
          tags_name_i_cont: q
        }
      end

    @articles = @articles.ransack(q_ransack.merge(m: 'or')).result(distinct: true)

    self
  end

  def localize
    @articles = @articles.where('locale like ?', "%#{@locale.to_s.split('-').first}%") if @filter != 'bought'

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
        @articles.where(author_id: @current_user&.subscribe_user_ids).order(published_at: :desc)
      when 'bought'
        @articles.where(id: @current_user&.bought_articles&.ids).order(published_at: :desc)
      else
        @articles.order_by_popularity
      end

    self
  end

  def select_in_time_range
    @articles =
      case @time_range
      when 'week'
        @articles.where(published_at: (1.week.ago)...)
      when 'month'
        @articles.where(published_at: (1.month.ago)...)
      when 'year'
        @articles.where(published_at: (1.year.ago)...)
      else
        @articles
      end

    self
  end

  def filter_block_by_authors
    @articles = @articles.where.not(author_id: @current_user.block_by_user_ids) if @current_user.present?

    self
  end

  def filter_block_authors
    @articles = @articles.where.not(author_id: @current_user.block_user_ids) if @current_user.present?

    self
  end
end
