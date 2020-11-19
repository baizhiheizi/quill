# frozen_string_literal: true

module Resolvers
  class CommentConnectionResolver < BaseResolver
    argument :commentable_type, String, required: false
    argument :commentable_id, ID, required: false
    argument :author_mixin_id, String, required: false
    argument :order_by, String, required: false
    argument :after, String, required: false

    type Types::CommentConnectionType, null: false

    def resolve(params = {})
      comments =
        if params[:commentable_id].present?
          commentable = Object.const_get(params[:commentable_type]).find_by(id: params[:commentable_id])
          raise 'Commentable Not Found!' if commentable.blank?

          commentable.comments
        elsif params[:author_mixin_id].present?
          author = User.find_by(mixin_id: params[:author_mixin_id])
          return if author.blank?

          author.comments
        else
          Comment.all
        end

      case params[:order_by]
      when 'asc'
        comments.order(created_at: :asc)
      when 'upvotes'
        comments.order(upvotes_count: :desc, downvotes_count: :asc)
      else
        comments.order(created_at: :desc)
      end
    end
  end
end
