# frozen_string_literal: true

module Mutations
  class ClearNotificationsMutation < Mutations::BaseMutation
    type Boolean

    def resolve
      current_user.notifications.destroy_all
    end
  end
end
