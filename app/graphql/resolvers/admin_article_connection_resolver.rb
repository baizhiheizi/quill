# frozen_string_literal: true

module Resolvers
  class AdminArticleConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params = {})
      Article.all.order(created_at: :desc)
    end
  end
end
