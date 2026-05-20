# frozen_string_literal: true

class SubscribeUserActionCreatedNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "PLAIN_TEXT"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :action

  notification_methods do
    def data
      message
    end

    def message
      [ params[:action].user.name.truncate(10), t(".subscribed") ].join(" ")
    end

    def url
      user_url params[:action].user.uid
    end

    def may_notify_via_mixin_bot?
      recipient_messenger?
    end
  end
end
