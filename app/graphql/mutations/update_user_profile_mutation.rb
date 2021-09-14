# frozen_string_literal: true

module Mutations
  class UpdateUserProfileMutation < Mutations::BaseMutation
    argument :uid, String, required: true

    type Boolean

    def resolve(params)
      current_user.assign_attributes(
        uid: params[:uid]
      )

      current_user.save
    end
  end
end
