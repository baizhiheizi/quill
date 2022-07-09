# frozen_string_literal: true

class ApplicationNotification < Noticed::Base
  deliver_by :action_cable, format: :format_for_action_cable

  around_action_cable :with_locale

  BATATA_ICON_URL = 'https://mixin-images.zeromesh.net/L0egX-GZxT0Yh-dd04WKeAqVNRzgzuj_Je_-yKf8aQTZo-xihd-LogbrIEr-WyG9WbJKGFvt2YYx-UIUa1qQMRla=s256'

  delegate :messenger?, to: :recipient, prefix: true

  private

  def message
  end

  def url
  end

  def format_for_action_cable
    message
  end

  def with_locale(&action)
    locale = recipient&.locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
