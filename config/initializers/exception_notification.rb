# frozen_string_literal: true

return unless Rails.env.production?

begin
  conversation_id = Rails.application.credentials.dig(:mixin_groups, :exception)
rescue ActiveSupport::MessageEncryptor::InvalidMessage
  Rails.logger.warn("Skipping ExceptionNotification: credentials could not be decrypted")
  return
end

return if conversation_id.blank?

Rails.application.config.middleware.use ExceptionNotification::Rack, mixin_bot: {
  conversation_id: conversation_id,
  bot: "QuillBot"
}
