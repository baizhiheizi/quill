# frozen_string_literal: true

module Resolvers
  class MyArticleOrderConnectionResolver < MyBaseResolver
    argument :uuid, ID, required: true
    argument :order_type, String, required: true
    argument :after, String, required: false

    type Types::OrderConnectionType, null: true

    def resolve(params)
      article = current_user.articles.find_by(uuid: params[:uuid])

      case params[:order_type]
      when 'buy_article'
        article.buy_orders.order(created_at: :desc)
      when 'reward_article'
        article.reward_orders.order(created_at: :desc)
      end
    end
  end
end
