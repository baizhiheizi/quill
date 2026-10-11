# frozen_string_literal: true

class UserConnectedNotifier < ApplicationNotifier
  # A one-time greeting that only makes sense inside Mixin Messenger.
  notifies :user_connected

  required_param :user

  notification_methods do
    def message
      t(".message")
    end
  end
end
