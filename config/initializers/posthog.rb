# frozen_string_literal: true

begin
  project_token = Rails.application.credentials.dig(:posthog, :project_token)
  host = Rails.application.credentials.dig(:posthog, :host)
rescue ActiveSupport::MessageEncryptor::InvalidMessage
  project_token = nil
  host = nil
end

if project_token.present?
  PostHog.init do |config|
    config.api_key = project_token
    config.host = host.presence || "https://us.i.posthog.com"
  end

  PostHog::Rails.configure do |config|
    config.auto_capture_exceptions = true
    config.report_rescued_exceptions = true
    config.auto_instrument_active_job = true
    config.capture_user_context = true
    config.current_user_method = :current_user
    config.user_id_method = :posthog_distinct_id
  end
end
