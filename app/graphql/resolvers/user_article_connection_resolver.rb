# frozen_string_literal: true

module Resolvers
  class UserArticleConnectionResolver < BaseResolver
    argument :mixin_id, ID, required: true
    argument :type, String, required: true
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      user = User.find_by mixin_id: params[:mixin_id]
      case params[:type]
      when 'author'
        user.articles.only_published.order(created_at: :desc)
      when 'reader'
        user.bought_articles.only_published
      end
    end
  end
end
