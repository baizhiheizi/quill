# frozen_string_literal: true

module Users::Scopable
  extend ActiveSupport::Concern

  included do
    default_scope { includes(:authorization) }
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
    scope :order_by_revenue_total, lambda {
      joins(revenue_transfers: :currency)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            SUM(transfers.amount * currencies.price_usd) AS revenue_total
          SQL
        ).order(revenue_total: :desc)
    }
    scope :order_by_orders_total, lambda {
      joins(:orders)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            SUM(orders.value_usd) AS orders_total
          SQL
        ).order(orders_total: :desc)
    }
    scope :order_by_articles_count, lambda {
      joins(:articles)
        .group(:id)
        .select(
          <<~SQL.squish
            users.*,
            COUNT(articles.id) AS articles_count
          SQL
        ).order(articles_count: :desc)
    }
    scope :order_by_comments_count, lambda {
      joins(:comments)
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
