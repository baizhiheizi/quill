# frozen_string_literal: true

module Resolvers
  class ArticleConnectionResolver < BaseResolver
    argument :after, String, required: false
    argument :order, String, required: true

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      case params[:order]
      when 'default'
        Article.order_by_popularity
      when 'lately'
        Article.only_published.order(created_at: :desc)
      when 'revenue'
        Article.only_published.order(revenue: :desc, orders_count: :desc)
      end
    end
  end
end
