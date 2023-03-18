# frozen_string_literal: true

module QuillBot
  def self.api
    @api ||= MixinBot::API.new(
      client_id: Rails.application.credentials.dig(:quill_bot, :client_id),
      client_secret: Rails.application.credentials.dig(:quill_bot, :client_secret),
      session_id: Rails.application.credentials.dig(:quill_bot, :session_id),
      pin_token: Rails.application.credentials.dig(:quill_bot, :pin_token),
      private_key: Rails.application.credentials.dig(:quill_bot, :private_key)
    )
  rescue StandardError => e
    Rails.logger.error e
    nil
  end
end
