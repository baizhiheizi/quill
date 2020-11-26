# frozen_string_literal: true

module Mutations
  class AdminUpdateBonusMutation < AdminBaseMutation
    argument :id, ID, required: true
    argument :user_id, ID, required: true
    argument :amount, Float, required: true
    argument :title, String, required: true
    argument :description, String, required: false

    field :error, String, null: true

    def resolve(params)
      bonus = Bonus.find(params[:id])
      bonus.update(
        ActionController::Parameters
          .new(params)
          .permit(
            :user_id,
            :amount,
            :title,
            :description
          )
      )

      {
        error: bonus.errors.full_messages.join(';').presence
      }
    end
  end
end
