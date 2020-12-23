# frozen_string_literal: true

class TextNotificationService
  def call(text, recipient_id:)
    message = PrsdiggBot.api.plain_text(
      conversation_id: PrsdiggBot.api.unique_conversation_id(recipient_id),
      data: text
    )

    SendMixinMessageWorker.perform_async message
  end
end
