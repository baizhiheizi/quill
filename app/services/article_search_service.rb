# frozen_string_literal: true

# Web-feed composition over `ArticleVisibility`. The JSON API, the home page
# and the article-reference picker use the module's predicates directly; this
# service only exists to keep the `ArticlesController#index` params → scope
# mapping in one place. The visibility rule itself lives in
# `ArticleVisibility`, not here.
class ArticleSearchService
  QUERY_LENGTH_LIMIT = ArticleVisibility::QUERY_LENGTH_LIMIT

  def self.call(*)
    new(*).call
  end

  def initialize(params = {})
    @query = ArticleVisibility.cap(params[:query])
    @tag = ArticleVisibility.cap(params[:tag])
    @filter = params[:filter]
    @time_range = params[:time_range]
    @current_user = params[:current_user]
  end

  def call
    relation = ArticleVisibility.for(@current_user, base: feed, hide_blocked_authors: hide_blocked_authors?)
    relation = relation.searching(@query)
    relation = relation.tagged(@tag)
    relation = filtered(relation)

    relation.in_range(@time_range)
  end

  private

  # Every non-draft article by a non-blocked platform author, preloaded for
  # the article card partial.
  def feed
    Article
      .with_associations
      .without_drafted
      .left_joins(:author)
      .where(users: { blocked_at: nil })
  end

  # The `bought` filter lists access the viewer already paid for, so the block
  # rule does not apply — same reason the article-reference picker bypasses it.
  def hide_blocked_authors?
    @filter != "bought"
  end

  def filtered(relation)
    case @filter
    when "lately"
      relation.only_published.ordered_by(:recent)
    when "revenue"
      relation.only_published.ordered_by(:revenue)
    when "subscribed"
      subscribed(relation)
    when "bought"
      relation.bought_by(@current_user).ordered_by(:recent)
    else
      relation.only_published.ordered_by(:popularity)
    end
  end

  def subscribed(relation)
    return relation.none if @current_user.blank?

    relation.only_published.subscribed_to(@current_user).ordered_by(:recent)
  end
end
