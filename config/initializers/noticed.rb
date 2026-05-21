# frozen_string_literal: true

module NoticedNotificationExtensions
  extend ActiveSupport::Concern

  MIXIN_ONLY_TYPES = %w[
    UserConnectedNotifier::Notification
    UserSafeRegistrationNotifier::Notification
  ].freeze

  included do
    scope :for_web, -> { where.not(type: MIXIN_ONLY_TYPES) }
  end

  def visible_in_web?
    notifier_class = event.type.constantize
    return false unless notifier_class.persist_web_notification
    return may_notify_via_web? if respond_to?(:may_notify_via_web?, true)
    return web_notification_enabled? if respond_to?(:web_notification_enabled?, true)

    true
  end

  def broadcast_as_flash
    return unless visible_in_web? && message.present?

    broadcast_prepend_later_to(
      "user_#{recipient.mixin_uuid}",
      target: "flashes",
      partial: "flashes/flash",
      locals: { message:, type: :info }
    )
  end
end

Rails.application.config.to_prepare do
  Noticed::Notification.include NoticedNotificationExtensions
end
