# frozen_string_literal: true

class HomeController < ApplicationController
  layout "homepage", only: :index

  def index
    redirect_to articles_path if current_user.present? || browser.device.mobile?
  end

  def selected_articles
    @articles = ArticleSearchService.call(filter: "revenue", time_range: "month", locale: current_locale).limit(6)
  end

  def hot_tags
    # Sample at the SQL level (`ORDER BY RANDOM() LIMIT 5`) and cache the
    # already-narrowed 5-row Array. The previous shape loaded `.limit(50)`
    # into the cache and then called `.sample(5)` in Ruby on every request
    # (Enumerable's `sample` first materializes the relation to a 50-row
    # Array, then picks 5). Caching the final 5 records keeps the cache
    # payload ~10x smaller in production and removes the per-request Ruby
    # sampling step.
    @hot_tags =
      Rails.cache.fetch "#{current_locale}_hot_tags", expires_in: 5.minutes do
        Tag
          .hot
          .where(locale: current_locale.to_s.split("-").first)
          .order(Arel.sql("RANDOM()"))
          .limit(5)
          .to_a
      end
  end

  def active_authors
    relation =
      User
      .active
      .where(locale: current_locale)
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
    @users = relation.limit(20).sample(5)
  end

  def more
    redirect_to root_path unless browser.device.mobile?
  end
end
