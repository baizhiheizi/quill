# frozen_string_literal: true

module Mutations
  class CreateCommentMutation < Mutations::BaseMutation
    argument :commentable_id, ID, required: true
    argument :commentable_type, String, required: true
    argument :content, String, required: true

    field :error, String, null: true
    field :commentable, Types::ArticleType, null: false

    def resolve(commentable_type:, commentable_id:, content:)
      commentable = Object.const_get(commentable_type).find_by(id: commentable_id)
      return { error: '找不到评论对象' } if commentable.blank?

      comment = commentable.comments.create(
        author: current_user,
        content: content
      )

      { error: comment.errors.full_messages.join(';').presence, commentable: commentable.reload }
    end
  end
end
