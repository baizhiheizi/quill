# frozen_string_literal: true

class ApplicationNotification < Noticed::Base
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
