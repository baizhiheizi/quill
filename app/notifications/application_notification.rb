# frozen_string_literal: true

class ApplicationNotification < Noticed::Base
  deliver_by :action_cable, format: :format_for_action_cable

  QUILL_ICON_URL = ActionController::Base.helpers.asset_url('quill.svg', host: Settings.host)

  delegate :messenger?, to: :recipient, prefix: true

  private

  def message
  end

  def url
  end

  def format_for_action_cable
    message
  end
end
