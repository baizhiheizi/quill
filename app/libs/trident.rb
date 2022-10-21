# frozen_string_literal: true

module Trident
  def self.api
    TridentAssistant::API.new(
      keystore: {
        client_id: QuillBot.api.client_id,
        session_id: QuillBot.api.session_id,
        pin_token: Base64.strict_encode64(QuillBot.api.pin_token),
        private_key: Base64.strict_encode64(QuillBot.api.private_key)
      }.to_json
    )
  end
end
