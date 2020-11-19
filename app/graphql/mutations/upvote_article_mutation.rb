# frozen_string_literal: true

module Mutations
  class UpvoteArticleMutation < Mutations::BaseMutation
    argument :uuid, ID, required: true

    type Types::ArticleType

    def resolve(uuid:)
      article = Article.find_by(uuid: uuid)
      return if article.blank?
      return if article.author == current_user
      return unless article.authorized? current_user

      article.with_lock do
        current_user.create_action :upvote, target: article
        current_user.destroy_action :downvote, target: article
      end

      article.reload
    end
  end
end
