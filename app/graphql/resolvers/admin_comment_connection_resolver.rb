# frozen_string_literal: true

module Resolvers
  class AdminCommentConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::CommentConnectionType, null: false

    def resolve(params = {})
      Comment.with_deleted.order(created_at: :desc)
    end
  end
end
