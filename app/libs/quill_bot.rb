# frozen_string_literal: true

module QuillBot
  def self.api
    @api ||= MixinBot::API.new **Rails.application.credentials.dig(:quill_bot), debug: Rails.env.development?
  rescue StandardError => e
    Rails.logger.error e
    nil
  end
end
