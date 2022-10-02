# frozen_string_literal: true

class ArticleSearchService
  def initialize(params = {})
    @query = params[:query].to_s.strip
    @tag = params[:tag].to_s.strip
    @filter = params[:filter]
    @time_range = params[:time_range]
    @current_user = params[:current_user]
    @locale = @query.to_s.strip.present? ? nil : params[:locale] || @current_user&.locale || I18n.default_locale
    @articles =
      Article
      .without_drafted
      .where(
        users: {
          blocked_at: nil
        }
      )
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    query
      .tagging
      .filter
      .filter_block_authors
      .filter_block_by_authors
      .select_in_time_range
      .localize

    @articles
  end

  def tagging
    @articles = @articles.joins(:currency, :tags, :author).ransack({ tags_name_i_cont_all: @tag }).result(distinct: true) if @tag.present?

    self
  end

  def query
    q_ransack = {
      title_i_cont: @query,
      intro_i_cont: @query,
      author_name_i_cont: @query,
      tags_name_i_cont: @query
    }

    @articles = @articles.joins(:currency, :tags, :author).ransack(q_ransack.merge(m: 'or')).result(distinct: true) if @query.present?

    self
  end

  def localize
    return self if @query.present?
    return self if @tag.present?
    return self if @locale.blank?
    return self if @filter.in? %w[subscribed bought]

    @articles = @articles.where(locale: @locale.to_s.split('-').first)

    self
  end

  def filter
    @articles =
      case @filter
      when 'lately'
        @articles.published.order(published_at: :desc)
      when 'revenue'
        @articles.published.order_by_revenue_usd
      when 'subscribed'
        @articles.published.where(author_id: @current_user&.subscribe_user_ids).order(published_at: :desc)
      when 'bought'
        @articles.where(id: @current_user&.bought_articles&.ids).order(published_at: :desc)
      else
        @articles.published.order_by_popularity
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
    return self if @filter == 'bought'

    @articles = @articles.where.not(author_id: @current_user.block_by_user_ids) if @current_user.present?

    self
  end

  def filter_block_authors
    return self if @filter == 'bought'

    @articles = @articles.where.not(author_id: @current_user.block_user_ids) if @current_user.present?

    self
  end
end
