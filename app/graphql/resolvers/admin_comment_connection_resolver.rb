# frozen_string_literal: true

module Resolvers
  class AdminCommentConnectionResolver < AdminBaseResolver
    argument :commentable_type, String, required: false
    argument :commentable_id, ID, required: false
    argument :author_mixin_uuid, String, required: false
    argument :after, String, required: false

    type Types::CommentConnectionType, null: false

    def resolve(**params)
      comments =
        if params[:commentable_id].present?
          commentable = Object.const_get(params[:commentable_type]).find_by(id: params[:commentable_id])
          raise 'Commentable Not Found!' if commentable.blank?

          commentable.comments
        elsif params[:author_mixin_uuid].present?
          author = User.find_by(mixin_uuid: params[:author_mixin_uuid])
          return if author.blank?

          author.comments
        else
          Comment.all
        end

      comments.with_deleted.order(created_at: :desc)
    end
  end
end
