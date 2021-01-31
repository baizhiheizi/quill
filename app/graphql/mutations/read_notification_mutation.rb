# frozen_string_literal: true

module Mutations
  class ReadNotificationMutation < Mutations::BaseMutation
    argument :id, ID, required: true

    type Types::NotificationType

    def resolve(id:)
      notification = current_user.notifications.find_by(id: id)
      notification&.mark_as_read!
      notification&.reload
    end
  end
end
