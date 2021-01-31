# frozen_string_literal: true

module Resolvers
  class MyNotificationConnectionResolver < MyBaseResolver
    argument :after, String, required: false
    argument :type, String, required: false

    type Types::NotificationConnectionType, null: false

    def resolve(**_params)
      current_user.notifications.order(created_at: :desc)
    end
  end
end
