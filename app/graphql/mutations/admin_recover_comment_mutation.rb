# frozen_string_literal: true

module Mutations
  class AdminRecoverCommentMutation < AdminBaseMutation
    argument :id, Int, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(id:)
      Comment.only_deleted.find_by(id: id)&.soft_undelete!

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
