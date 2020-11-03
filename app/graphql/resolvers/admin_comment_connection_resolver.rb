# frozen_string_literal: true

module Resolvers
  class AdminCommentConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::CommentConnectionType, null: false

    def resolve(params = {})
      Comment.all.order(created_at: :desc)
    end
  end
end
