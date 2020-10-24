# frozen_string_literal: true

module Resolvers
  class ArticleConnectionResolver < BaseResolver
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(_params)
      Article.order(created_at: :desc)
    end
  end
end
