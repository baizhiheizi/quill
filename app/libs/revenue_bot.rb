# frozen_string_literal: true

# `MixinApi.wrap` is defined in gate.rb, which Zeitwerk loads only when
# `MixinApi::Gate` is referenced. Name it here: without it, a lazy-loaded
# process whose first touch is RevenueBot.api (development server/console)
# rescues the missing-method error into a nil client and silently falls back
# to QuillBot.
require_dependency "mixin_api/gate"

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
