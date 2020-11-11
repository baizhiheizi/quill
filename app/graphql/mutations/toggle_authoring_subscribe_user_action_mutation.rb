# frozen_string_literal: true

module Mutations
  class ToggleAuthoringSubscribeUserActionMutation < Mutations::BaseMutation
    argument :mixin_id, String, required: true

    field :error, String, null: true

    def resolve(params)
      user = User.find_by(mixin_id: params[:mixin_id])
      return { error: '找不到用户' } if user.blank?
      return { error: '不能订阅自己' } if current_user == user

      if current_user.authoring_subscribe_user?(user)
        current_user.destroy_action(:authoring_subscribe, target: user)
      else
        current_user.create_action(:authoring_subscribe, target: user)
      end

      { error: nil }
    end
  end
end
