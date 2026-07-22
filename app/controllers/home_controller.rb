# frozen_string_literal: true

class HomeController < ApplicationController
  layout "public", only: %i[index hot_tags active_authors selected_articles more]

  def index
    redirect_to articles_path if current_user.present? || browser.device.mobile?

    @platform_stats = {
      articles:   cached_article_count,
      authors:    cached_active_author_count,
      revenue_label: cached_revenue_label
    }
  end

  def selected_articles
    @articles = ArticleSearchService.call(filter: "revenue", time_range: "month", current_user:).limit(6)
  end

  def hot_tags
    # Sample at the SQL level (`ORDER BY RANDOM() LIMIT 5`) and cache the
    # already-narrowed 5-row Array. The previous shape loaded `.limit(50)`
    # into the cache and then called `.sample(5)` in Ruby on every request
    # (Enumerable's `sample` first materializes the relation to a 50-row
    # Array, then picks 5). Caching the final 5 records keeps the cache
    # payload ~10x smaller in production and removes the per-request Ruby
    # sampling step.
    #
    # Cross-Locale Article Visibility: cache key is process-wide (no per-locale
    # suffix) and the tag relation is no longer narrowed by `tags.locale =
    # caller_locale`. Every visitor sees the platform-wide hot-tag set.
    @hot_tags =
      Rails.cache.fetch "hot_tags", expires_in: 5.minutes, race_condition_ttl: 30.seconds do
        Tag
          .hot
          .order(Arel.sql("RANDOM()"))
          .limit(5)
          .to_a
      end
  end

  def active_authors
    # Cross-Locale Article Visibility: the relation is no longer narrowed
    # by `users.locale = caller_locale`. Every visitor sees the
    # platform-wide active-author set.
    relation =
      User
      .active
    if current_user
      # Same SQL subquery pattern as ArticleSearchService#filter_block_authors
      # (PR #1598): never materialize the blocked user IDs in Ruby. The
      # `actions` table has an index on (user_type, user_id, action_type),
      # so the IN-list subquery is index-scannable.
      blocked_ids =
        Action
        .where(user_id: current_user.id, action_type: "block", target_type: "User")
        .select(:target_id)
      relation = relation.where.not(id: blocked_ids).where.not(id: current_user.id)
    end
    # Same SQL-sample pattern as `hot_tags`: `ORDER BY RANDOM() LIMIT 5` lets
    # Postgres pick 5 rows directly from the filtered relation instead of
    # shipping 20 rows over the wire and discarding 15 in Ruby. The previous
    # `.limit(20).sample(5)` shape was 75% wasted bytes (20 rows for 5) plus
    # an Enumerable#sample call after the AR relation materialised. We don't
    # cache the result here (unlike `hot_tags`) because the sample depends
    # on the per-visitor blocked-user set — caching would return identical
    # authors to every signed-in visitor regardless of their blocks.
    @users = relation.order(Arel.sql("RANDOM()")).limit(5).to_a
  end

  def more
    redirect_to root_path unless browser.device.mobile?
  end

  private

  def format_revenue_stat(total)
    total = total.to_f
    return "$0" if total <= 0

    if total >= 1_000_000
      "$#{(total / 1_000_000).round(1)}M"
    elsif total >= 1_000
      "$#{(total / 1_000).round(1)}K"
    else
      "$#{total.round(0)}"
    end
  end

  # Platform-wide article count — changes only when articles are published
  # or unpublished. Cached 5 minutes with race-condition protection, matching
  # the existing hot_tags caching strategy (see #hot_tags).
  def cached_article_count
    Rails.cache.fetch "platform_stats/articles", expires_in: 5.minutes, race_condition_ttl: 30.seconds do
      Article.only_published.count
    end
  end

  # Distinct active (3-month window, ≥1 paid order) author count. Same slow
  # churn rate as article count; caching avoids this aggregate on every
  # unauthenticated landing-page visit.
  def cached_active_author_count
    Rails.cache.fetch "platform_stats/authors", expires_in: 5.minutes, race_condition_ttl: 30.seconds do
      User.active_base.distinct.count(:id)
    end
  end

  # Formatted total reader revenue (e.g. "$12.3K"). Sums `revenue_usd` across
  # published articles. Cache key embedded so different formats never collide.
  def cached_revenue_label
    Rails.cache.fetch "platform_stats/revenue_label", expires_in: 5.minutes, race_condition_ttl: 30.seconds do
      format_revenue_stat(Article.only_published.sum(:revenue_usd))
    end
  end
end
