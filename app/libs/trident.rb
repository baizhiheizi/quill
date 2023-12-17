# frozen_string_literal: true

module Trident
  def self.api
    TridentAssistant::API.new(
      keystore: {
        client_id: Rails.application.credentials.dig(:quill_bot, :client_id),
        session_id: Rails.application.credentials.dig(:quill_bot, :session_id),
        pin_token: Rails.application.credentials.dig(:quill_bot, :pin_token),
        private_key: Rails.application.credentials.dig(:quill_bot, :private_key),
        pin: Rails.application.credentials.dig(:quill_bot, :pin)
      }.to_json
    )
  rescue StandardError => e
    Rails.logger.error e
    nil
  end
end
