# frozen_string_literal: true

require "omniauth/mixin"

Rails.application.config.middleware.use OmniAuth::Builder do
  client_id = Rails.application.credentials.dig(:quill_bot, :client_id)
  client_secret = Rails.application.credentials.dig(:quill_bot, :client_secret)

  if Rails.env.test?
    provider :mixin, "test-client-id", "test-client-secret", scope: "PROFILE:READ"
  elsif client_id.present? && client_secret.present?
    provider :mixin, client_id, client_secret, scope: "PROFILE:READ"
  end
end
