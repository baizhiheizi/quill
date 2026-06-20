# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  class_attribute :persist_web_notification, default: true

  deliver_by :action_cable do |config|
    config.message = :format_for_action_cable
    config.if = -> { visible_in_web? && message.present? }
  end

  deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast" do |config|
    config.if = -> { visible_in_web? && message.present? }
  end

  QUILL_ICON_URL = ActionController::Base.helpers.asset_path(Settings.icon_file)

  notification_methods do
    def format_for_action_cable
      I18n.with_locale(recipient&.locale || I18n.default_locale) { message }
    end

    def message
    end

    def url
    end

    def icon_url
    end

    def recipient_messenger?
      recipient.messenger?
    end
  end
end
