# frozen_string_literal: true

class ArticleSearchService
  # Cap query length so a long `query` param can't bloat the ILIKE pattern
  # into an expensive seq-scan. Pairs with the pg_trgm GIN indexes (see
  # db/migrate/*_add_pg_trgm_indexes_for_search.rb).
  QUERY_LENGTH_LIMIT = 64

  def initialize(params = {})
    @query = params[:query].to_s.strip.first(QUERY_LENGTH_LIMIT)
    @tag = params[:tag].to_s.strip.first(QUERY_LENGTH_LIMIT)
    @filter = params[:filter]
    @time_range = params[:time_range]
    @current_user = params[:current_user]
    @articles =
      Article
      .with_associations
      .without_drafted
      .left_joins(:author)
      .where(
        users: {
          blocked_at: nil
        }
      )
  end

  def self.call(*)
    new(*).call
  end

  def call
    query
      .tagging
      .filter
      .filter_block_authors
      .select_in_time_range

    @articles
  end

  def tagging
    @articles = @articles.ransack({ tags_name_i_cont_all: @tag }).result(distinct: true) if @tag.present?

    self
  end

  def query
    q_ransack = {
      title_i_cont: @query,
      intro_i_cont: @query,
      author_name_i_cont: @query,
      tags_name_i_cont: @query
    }

    @articles = @articles.ransack(q_ransack.merge(m: "or")).result(distinct: true) if @query.present?

    self
  end

  def filter
    @articles =
      case @filter
      when "lately"
        @articles.published.order(published_at: :desc)
      when "revenue"
        @articles.published.order_by_revenue_usd
      when "subscribed"
        return @articles.none if @current_user.blank?

        # Inline as subqueries so we never materialize every subscribed-author
        # ID or owned-collection UUID in Ruby. Matches the pattern used by
        # `bought_articles&.select(:id)` in the filter below.
        subscribed_author_ids =
          Action
            .where(user_id: @current_user.id, action_type: "subscribe", target_type: "User")
            .select(:target_id)
        owned_collection_uuids =
          Collection
            .joins(:buy_orders)
            .where(buy_orders: { buyer_id: @current_user.id })
            .select(:uuid)

        @articles.published
                 .where(author_id: subscribed_author_ids)
                 .or(
                   @articles
                     .published
                     .where(collection_id: owned_collection_uuids)
                 ).order(published_at: :desc)
      when "bought"
        @articles.where(id: @current_user&.bought_articles&.select(:id)).order(published_at: :desc)
      else
        @articles.published.order_by_popularity
      end

    self
  end

  def select_in_time_range
    @articles =
      case @time_range
      when "week"
        @articles.where(published_at: (1.week.ago)...)
      when "month"
        @articles.where(published_at: (1.month.ago)...)
      when "year"
        @articles.where(published_at: (1.year.ago)...)
      else
        @articles
      end

    self
  end

  def filter_block_authors
    return self if @filter == "bought" || @current_user.blank?

    # Subqueries exclude (a) authors @current_user has blocked and (b) authors
    # who have blocked @current_user. Matches the `subscribed` filter pattern:
    # never materialize IDs in Ruby, let SQL handle the predicate.
    blocked_ids =
      Action
        .where(user_id: @current_user.id, action_type: "block", target_type: "User")
        .select(:target_id)
    blockers_ids =
      Action
        .where(target_id: @current_user.id, target_type: "User", user_type: "User", action_type: "block")
        .select(:user_id)

    @articles = @articles.where.not(author_id: blocked_ids).where.not(author_id: blockers_ids)

    self
  end
end
