# frozen_string_literal: true

module Mutations
  class ToggleSubscribeTagActionMutation < Mutations::BaseMutation
    argument :id, ID, required: true

    type Types::TagType

    def resolve(params)
      tag = Tag.find_by(id: params[:id])
      return { error: '找不到话题' } if tag.blank?

      if current_user.subscribe_tag?(tag)
        current_user.destroy_action(:subscribe, target: tag)
      else
        current_user.create_action(:subscribe, target: tag)
      end

      tag.reload
    end
  end
end
