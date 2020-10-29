# frozen_string_literal: true

module Resolvers
  class CommentConnectionResolver < BaseResolver
    argument :commentable_type, String, required: true
    argument :commentable_id, Int, required: true
    argument :after, String, required: false

    type Types::CommentConnectionType, null: false

    def resolve(params)
      commentable = Object.const_get(params[:commentable_type]).find_by(id: params[:commentable_id])
      return if commentable.blank?

      commentable.comments
    end
  end
end
