# frozen_string_literal: true

module Mutations
  class AdminCreateBonusMutation < AdminBaseMutation
    argument :user_id, ID, required: true
    argument :amount, Float, required: true
    argument :title, String, required: true
    argument :description, String, required: false

    field :error, String, null: true

    def resolve(params)
      bonus =
        Bonus.new(
          ActionController::Parameters
          .new(params)
          .permit(
            :user_id,
            :amount,
            :title,
            :description
          )
        )
      bonus.save

      {
        error: bonus.errors.full_messages.join(';').presence
      }
    end
  end
end
