# frozen_string_literal: true

module Mutations
  class DownvoteArticleMutation < Mutations::BaseMutation
    argument :uuid, ID, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(uuid:)
      article = Article.find_by(uuid: uuid)
      return { error: '找不到文章' } if article.blank?
      return { error: '作者不能评价' } if article.author == current_user
      return { error: '不是读者' } unless article.authorized? current_user

      article.with_lock do
        current_user.create_action :downvote, target: article
        current_user.destroy_action :upvote, target: article
      end

      {
        success: true
      }
    rescue StandardError => e
      {
        error: e.to_s
      }
    end
  end
end
