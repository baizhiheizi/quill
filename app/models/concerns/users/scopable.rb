# frozen_string_literal: true

module Users::Scopable
  extend ActiveSupport::Concern

  included do
    scope :with_authorization, -> { includes(:authorization) }
    scope :only_blocked, -> { where.not(blocked_at: nil) }
    scope :without_blocked, -> { where(blocked_at: nil) }
    scope :only_mixin_messenger, -> { where(authorization: { provider: :mixin }) }

    scope :active_base, lambda {
      without_blocked
        .joins(:articles)
        .where(
          articles: { created_at: (3.months.ago)..., orders_count: 1... }
        )
    }

    scope :active, lambda {
      active_base
        .group(:id)
        .select("users.*, COUNT(articles.id) AS active_articles_count")
        .order(active_articles_count: :desc, id: :asc)
    }
    scope :only_email_verified, -> { where.not(email_verified_at: nil) }
    scope :only_validated, -> { where.not(validated_at: nil) }
    # `order_by_articles_count` and `order_by_comments_count` order on the
    # `users.articles_count` / `users.comments_count` counter-cache columns
    # maintained by `Article` / `Comment#belongs_to :author, counter_cache: true`.
    # No JOIN, no GROUP BY, no aggregate — the same row order as the previous
    # LEFT JOIN + COUNT shape, but with a constant-cost sort.
    #
    # `order_by_revenue_total` and `order_by_orders_total` still aggregate at
    # query time because the underlying numbers are sums, not cached counters.
    # They use LEFT JOIN + COALESCE so users with no matching rows are still
    # included with a 0 value. Same pattern as `Article.order_by_popularity`
    # (PR #1539) and the `subscribed` / `block` filters.
    scope :order_by_revenue_total, lambda {
      left_joins(revenue_transfers: :currency)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            COALESCE(SUM(transfers.amount * currencies.price_usd), 0) AS revenue_total
          SQL
        ).order(revenue_total: :desc)
    }
    scope :order_by_orders_total, lambda {
      left_joins(:orders)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            COALESCE(SUM(orders.value_usd), 0) AS orders_total
          SQL
        ).order(orders_total: :desc)
    }
    scope :order_by_articles_count, lambda {
      order(articles_count: :desc, id: :asc)
    }
    scope :order_by_comments_count, lambda {
      order(comments_count: :desc, id: :asc)
    }
  end
end
