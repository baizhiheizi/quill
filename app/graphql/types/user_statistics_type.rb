# frozen_string_literal: true

module Types
  class UserStatisticsType < BaseObject
    field :articles_count, Integer, null: false
    field :author_revenue_amount, Float, null: false
    field :bought_articles_count, Integer, null: false
    field :reader_revenue_amount, Float, null: false
    field :comments_count, Integer, null: false
    field :revenue_total, Float, null: false
    field :payment_total, Float, null: false
  end
end
