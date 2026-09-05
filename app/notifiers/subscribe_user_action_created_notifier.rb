# frozen_string_literal: true

class SubscribeUserActionCreatedNotifier < ApplicationNotifier
  notifies :subscribe_user_action_created

  required_param :action

  notification_methods do
    def message
      [ params[:action].user.name.truncate(10), t(".subscribed") ].join(" ")
    end

    def url
      user_url params[:action].user.uid
    end
  end
end
