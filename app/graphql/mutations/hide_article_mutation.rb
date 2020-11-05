# frozen_string_literal: true

module Mutations
  class HideArticleMutation < Mutations::BaseMutation
    argument :uuid, ID, required: true

    field :error, String, null: true
    field :success, Boolean, null: true

    def resolve(uuid:)
      current_user.articles.find_by(uuid: uuid)&.hide!

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
