# frozen_string_literal: true

module Mutations
  class AdminUnblockArticleMutation < AdminBaseMutation
    argument :uuid, ID, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(uuid:)
      Article.find_by(uuid: uuid)&.unblock!

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
