# frozen_string_literal: true

module Mutations
  class ToggleCommentingSubscribeArticleActionMutation < Mutations::BaseMutation
    argument :uuid, ID, required: true

    type Types::ArticleType

    def resolve(params)
      article = Article.find_by(uuid: params[:uuid])
      return { error: '找不到文章' } if article.blank?

      if current_user.commenting_subscribe_article?(article)
        current_user.destroy_action(:commenting_subscribe, target: article)
      else
        current_user.create_action(:commenting_subscribe, target: article)
      end

      article.reload
    end
  end
end
