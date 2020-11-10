# frozen_string_literal: true

module Resolvers
  class CommentConnectionResolver < BaseResolver
    argument :commentable_type, String, required: false
    argument :commentable_id, Int, required: false
    argument :author_mixin_id, String, required: false
    argument :after, String, required: false

    type Types::CommentConnectionType, null: false

    def resolve(params = {})
      if params[:commentable_id].present?
        commentable = Object.const_get(params[:commentable_type]).find_by(id: params[:commentable_id])
        return if commentable.blank?

        commentable.comments.order(created_at: :desc)
      elsif params[:author_mixin_id].present?
        author = User.find_by(mixin_id: params[:author_mixin_id])
        return if author.blank?

        author.comments.order(created_at: :desc)
      else
        Comment.all.order(created_at: :desc)
      end
    end
  end
end
