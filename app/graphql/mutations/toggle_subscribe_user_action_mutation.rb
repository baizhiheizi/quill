# frozen_string_literal: true

module Mutations
  class ToggleSubscribeUserActionMutation < Mutations::BaseMutation
    argument :uid, String, required: true

    type Boolean

    def resolve(params)
      user = User.find_by(uid: params[:uid])
      return if user.blank? || current_user == user

      if current_user.subscribe_user?(user)
        current_user.destroy_action(:subscribe, target: user)
      else
        current_user.create_action(:subscribe, target: user)
      end
    end
  end
end
