# frozen_string_literal: true

class TextNotificationService
  def call(text, recipient_id:)
    message = QuillBot.api.plain_text(
      conversation_id: QuillBot.api.unique_conversation_id(recipient_id),
      data: text
    )

    MixinMessages::SendJob.perform_later message.stringify_keys
  end
end
