# frozen_string_literal: true

module NoticedNotificationExtensions
  extend ActiveSupport::Concern

  included do
    # Written from the notification-kind declaration when the row is created,
    # so the inbox is a plain indexed query.
    scope :for_web, -> { where(web_visible: true) }
  end

  def broadcast_as_flash
    return unless web_visible? && message.present?

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
