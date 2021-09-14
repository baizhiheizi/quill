# frozen_string_literal: true

module Mutations
  class SyncUserProfileMutation < Mutations::BaseMutation
    type Types::UserType

    def resolve
      res = PrsdiggBot.api.read_user current_user.mixin_uuid

      current_user.mixin_authorization.update(
        raw: res['data']
      )

      current_user.update_profile

      current_user.reload
    end
  end
end
