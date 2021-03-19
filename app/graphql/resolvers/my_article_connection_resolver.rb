# frozen_string_literal: true

module Resolvers
  class MyArticleConnectionResolver < MyBaseResolver
    argument :type, String, required: true
    argument :state, String, required: false
    argument :after, String, required: false

    type Types::ArticleConnectionType, null: false

    def resolve(params)
      case params[:type]
      when 'author'
        articles =
          if params[:state].present?
            current_user.articles.where(state: params[:state])
          else
            current_user.articles
          end
        articles.order(created_at: :desc)
      when 'reader'
        current_user.bought_articles
      end
    end
  end
end
