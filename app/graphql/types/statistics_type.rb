# frozen_string_literal: true

module Types
  class StatisticsType < BaseObject
    field :author_revenue_amount, Float, null: false
    field :reader_revenue_amount, Float, null: false
    field :articles_count, Integer, null: false
    field :users_count, Integer, null: false
  end
end
