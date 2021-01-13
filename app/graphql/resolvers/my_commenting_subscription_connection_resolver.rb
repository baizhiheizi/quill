# frozen_string_literal: true

module Resolvers
  class MyCommentingSubscriptionConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(**)
      current_user.commenting_subscribe_articles
    end
  end
end
