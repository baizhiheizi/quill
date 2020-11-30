# frozen_string_literal: true

class TextNotificationService
  def call(text, recipient_id:)
    message = MixinBot.api.plain_text(
      conversation_id: MixinBot.api.unique_conversation_id(recipient_id),
      data: text
    )

    SendMixinMessageWorker.perform_async message
  end
end
