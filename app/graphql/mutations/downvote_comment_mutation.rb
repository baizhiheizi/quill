# frozen_string_literal: true

module Mutations
  class DownvoteCommentMutation < Mutations::BaseMutation
    argument :id, ID, required: true

    type Types::CommentType

    def resolve(id:)
      comment = Comment.find_by(id: id)
      return if comment.blank?
      return if comment.author == current_user
      return unless comment.commentable.authorized? current_user

      comment.with_lock do
        current_user.destroy_action :upvote, target: comment
        current_user.create_action :downvote, target: comment
      end

      comment.reload
    end
  end
end
