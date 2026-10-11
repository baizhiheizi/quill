# frozen_string_literal: true

class UserSafeRegistrationNotifier < ApplicationNotifier
  # Delivered before the recipient can be trusted to accept transfers, so it
  # only makes sense inside Mixin Messenger.
  notifies :user_safe_registration

  required_param :user

  notification_methods do
    def message
      t(".message")
    end
  end
end
