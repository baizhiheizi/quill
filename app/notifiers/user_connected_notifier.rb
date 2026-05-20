# frozen_string_literal: true

class UserConnectedNotifier < ApplicationNotifier
  self.persist_web_notification = false

  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "PLAIN_TEXT"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :user

  notification_methods do
    def data
      message
    end

    def message
      t(".message")
    end

    def url
    end

    def may_notify_via_mixin_bot?
      recipient_messenger?
    end
  end
end
