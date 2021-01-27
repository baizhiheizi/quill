# frozen_string_literal: true

module Mutations
  class ReadNotificationsMutation < Mutations::BaseMutation
    type Boolean

    def resolve
      current_user.notifications.map(&:mark_as_read!)
    end
  end
end
