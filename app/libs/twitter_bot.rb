# frozen_string_literal: true

module TwitterBot
  def self.oauth_client
    TwitterOAuth2::Client.new(
      identifier: Rails.application.credentials.dig(:twitter, :client_id),
      secret: Rails.application.credentials.dig(:twitter, :client_secret),
      redirect_uri: "#{Settings.host}/auth/twitter/callback"
    )
  rescue StandardError => e
    Rails.logger.error e
    nil
  end
end
