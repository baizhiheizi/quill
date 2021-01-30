# frozen_string_literal: true

module Resolvers
  class MyNotificationSettingResolver < MyBaseResolver
    type Types::NotificationSettingType, null: false

    def resolve
      current_user.notification_setting
    end
  end
end
