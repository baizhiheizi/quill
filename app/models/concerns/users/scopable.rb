# frozen_string_literal: true

module Users::Scopable
  extend ActiveSupport::Concern

  included do
    scope :with_authorization, -> { includes(:authorization) }
    scope :only_blocked, -> { where.not(blocked_at: nil) }
    scope :without_blocked, -> { where(blocked_at: nil) }
    scope :only_mixin_messenger, -> { where(authorization: { provider: :mixin }) }
    scope :only_fennec, -> { where(authorization: { provider: :fennec }) }
    scope :only_mvm, -> { where(authorization: { provider: :mvm_eth }) }

    scope :active, lambda {
      without_blocked
        .order_by_articles_count
        .where(
          articles: { created_at: (3.months.ago)..., orders_count: 1... }
        )
    }
    scope :only_email_verified, -> { where.not(email_verified_at: nil) }
    scope :only_validated, -> { where.not(validated_at: nil) }
    # All order_by_* scopes use LEFT JOIN so users with no matching rows
    # (no revenue transfers, no orders, no articles, no comments) are still
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
      left_joins(:articles)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            COUNT(articles.id) AS articles_count
          SQL
        ).order(articles_count: :desc)
    }
    scope :order_by_comments_count, lambda {
      left_joins(:comments)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            COUNT(comments.id) AS comments_count
          SQL
        ).order(comments_count: :desc)
    }
  end
end
