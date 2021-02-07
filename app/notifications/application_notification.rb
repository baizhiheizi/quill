# frozen_string_literal: true

class ApplicationNotification < Noticed::Base
  PRSDIGG_ICON_URL = 'https://mixin-images.zeromesh.net/L0egX-GZxT0Yh-dd04WKeAqVNRzgzuj_Je_-yKf8aQTZo-xihd-LogbrIEr-WyG9WbJKGFvt2YYx-UIUa1qQMRla=s256'

  private

  def message
  end

  def url
  end

  def web_notification_enabled?
    true
  end

  def mixin_bot_notification_enabled?
    true
  end
end
