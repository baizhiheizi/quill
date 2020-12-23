# frozen_string_literal: true

module DashboardBot
  def self.api
    @api ||= MixinBot::API.new(
      client_id: Rails.application.credentials.dig(:dashboard_bot, :client_id),
      client_secret: Rails.application.credentials.dig(:dashboard_bot, :client_secret),
      session_id: Rails.application.credentials.dig(:dashboard_bot, :session_id),
      pin_token: Rails.application.credentials.dig(:dashboard_bot, :pin_token),
      private_key: Rails.application.credentials.dig(:dashboard_bot, :private_key)
    )
  end
end
