# frozen_string_literal: true

module Types
  class UserStatisticsType < BaseObject
    field :articles_count, Integer, null: false
    field :author_revenue_total, Float, null: false
    field :bought_articles_count, Integer, null: false
    field :reader_revenue_total, Float, null: false
    field :comments_count, Integer, null: false
    field :revenue_total, Float, null: false
    field :payment_total, Float, null: false

    def articles_count
      object['articles_count'] || 0
    end

    def author_revenue_total
      object['author_revenue_total'] || 0
    end

    def bought_articles_count
      object['bought_articles_count'] || 0
    end

    def reader_revenue_total
      object['reader_revenue_total'] || 0
    end

    def comments_count
      object['comments_count'] || 0
    end

    def revenue_total
      object['revenue_total'] || 0
    end

    def payment_total
      object['payment_total'] || 0
    end
  end
end
