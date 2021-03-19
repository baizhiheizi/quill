# frozen_string_literal: true

module Types
  class UserStatisticsType < BaseObject
    field :articles_count, Integer, null: true
    field :bought_articles_count, Integer, null: true
    field :comments_count, Integer, null: true

    field :author_revenue_total_prs, Float, null: true
    field :reader_revenue_total_prs, Float, null: true
    field :revenue_total_prs, Float, null: true
    field :payment_total_prs, Float, null: true

    field :author_revenue_total_btc, Float, null: true
    field :reader_revenue_total_btc, Float, null: true
    field :revenue_total_btc, Float, null: true
    field :payment_total_btc, Float, null: true

    field :author_revenue_total_usd, Float, null: true
    field :reader_revenue_total_usd, Float, null: true
    field :revenue_total_usd, Float, null: true
    field :payment_total_usd, Float, null: true

    def author_revenue_total_usd
      object['author_revenue_total_prs'].to_f * Currency.prs.price_usd.to_f + object['author_revenue_total_btc'].to_f * Currency.btc.price_usd.to_f
    end

    def reader_revenue_total_usd
      object['reader_revenue_total_prs'].to_f * Currency.prs.price_usd.to_f + object['reader_revenue_total_btc'].to_f * Currency.btc.price_usd.to_f.to_f
    end

    def revenue_total_usd
      author_revenue_total_usd + reader_revenue_total_usd
    end

    def payment_total_usd
      object['payment_total_usd'] || 0.0
    end
  end
end
