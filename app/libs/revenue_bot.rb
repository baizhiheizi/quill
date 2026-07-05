# frozen_string_literal: true

module RevenueBot
  def self.api
    @api ||= MixinApi.wrap(build_api, scope: :revenue_bot, mode: :background)
  rescue StandardError
    nil
  end

  def self.build_api
    MixinBot::API.new(
      client_id: Rails.application.credentials.dig(:revenue_bot, :client_id),
      client_secret: Rails.application.credentials.dig(:revenue_bot, :client_secret),
      session_id: Rails.application.credentials.dig(:revenue_bot, :session_id),
      pin_token: Rails.application.credentials.dig(:revenue_bot, :pin_token),
      private_key: Rails.application.credentials.dig(:revenue_bot, :private_key)
    )
  end
  private_class_method :build_api
end
