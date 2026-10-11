# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  class_attribute :notification_kind, instance_writer: false, default: nil

  deliver_by :action_cable do |config|
    config.message = :format_for_action_cable
    config.if = -> { web_visible? && message.present? }
  end

  deliver_by :flash_broadcast, class: "DeliveryMethods::FlashBroadcast" do |config|
    config.if = -> { web_visible? && message.present? }
  end

  QUILL_ICON_URL = ActionController::Base.helpers.asset_path(Settings.icon_file)

  class << self
    # Declares which `NotificationKind` entry this notifier implements. The
    # kind carries the Mixin category, the bot and the inbox visibility; the
    # delivery config and the delivery guards below are derived from it.
    def notifies(name)
      kind = NotificationKind.fetch(name)
      self.notification_kind = kind

      deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
        config.category = kind.mixin_category
        config.bot = kind.bot if kind.bot
        config.if = -> { may_notify_via_mixin_bot? }
      end
    end

    def notification_class
      const_get :Notification
    end
  end

  # The inbox decision is made once, here, and denormalised onto the row so no
  # reader has to re-derive it from the notifier class and mutable settings.
  def recipient_attributes_for(recipient)
    super.merge web_visible: notification_kind.web? && delivery_candidate(recipient).may_notify_via_web?
  end

  notification_methods do
    delegate :notification_kind, to: :event

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

    # -- delivery guards, derived from the kind declaration -------------------

    def may_notify_via_web?
      web_notification_enabled? && should_notify?
    end

    def may_notify_via_mixin_bot?
      recipient_messenger? && mixin_bot_notification_enabled? && should_notify?
    end

    # Kinds without settings are always on; kinds with settings read the two
    # toggles `NotificationSetting` stores for them. A recipient with no
    # preferences row at all has not opted out of anything.
    def web_notification_enabled?
      setting_for(:web)
    end

    def mixin_bot_notification_enabled?
      setting_for(:mixin_bot)
    end

    def should_notify?
      true
    end

    # -- payload --------------------------------------------------------------

    # Cards carry the four APP_CARD keys; text kinds send the bare message.
    def data
      return message unless notification_kind.card?

      {
        icon_url:,
        title: title.truncate(36),
        description: description.truncate(72),
        action: url
      }
    end

    def title
      raise NotImplementedError, "#{event.class.name} declares a card kind and must define #title"
    end

    def description
      message
    end

    private

    def setting_for(channel)
      return true unless notification_kind.settings?

      setting = recipient.notification_setting
      setting ? setting.public_send(notification_kind.setting_key(channel)) : true
    end
  end

  private

  # The guards live on the notification (they read its params and recipient),
  # so borrow an unsaved one to evaluate them for a recipient at delivery time.
  def delivery_candidate(recipient)
    self.class.notification_class.new event: self, recipient: recipient
  end
end
