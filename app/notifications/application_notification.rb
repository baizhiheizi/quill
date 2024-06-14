# frozen_string_literal: true

class ApplicationNotification < Noticed::Base
  deliver_by :action_cable, format: :format_for_action_cable

  around_action_cable :with_locale

  QUILL_ICON_URL = ActionController::Base.helpers.asset_path(Settings.icon_file || 'icon.png')

  delegate :messenger?, to: :recipient, prefix: true

  private

  def message
  end

  def url
  end

  def icon_url
  end

  def format_for_action_cable
    message
  end

  def with_locale(&)
    locale = recipient&.locale || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
