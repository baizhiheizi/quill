# frozen_string_literal: true

class ApplicationNotification < Noticed::Base
  deliver_by :action_cable, format: :format_for_action_cable

  around_action_cable :with_locale

  PRSDIGG_ICON_URL = 'https://mixin-images.zeromesh.net/L0egX-GZxT0Yh-dd04WKeAqVNRzgzuj_Je_-yKf8aQTZo-xihd-LogbrIEr-WyG9WbJKGFvt2YYx-UIUa1qQMRla=s256'

  private

  def message
  end

  def url
  end

  def format_for_action_cable
    message
  end

  def web_notification_enabled?
    true
  end

  def mixin_bot_notification_enabled?
    true
  end

  def with_locale(&action)
    locale = recipient&.locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
