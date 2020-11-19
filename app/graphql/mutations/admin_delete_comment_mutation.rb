# frozen_string_literal: true

module Mutations
  class AdminDeleteCommentMutation < AdminBaseMutation
    argument :id, ID, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(id:)
      Comment.without_deleted.find_by(id: id)&.soft_delete!

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
