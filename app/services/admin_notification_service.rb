# frozen_string_literal: true

class AdminNotificationService
  def text(text)
    return if Rails.application.credentials.dig(:admin, :group_conversation_id).blank?

    message = QuillBot.api.plain_text(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: text
    )
    SendMixinMessageWorker.perform_async message.stringify_keys
  end

  def post(post)
    message = QuillBot.api.plain_post(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: post
    )
    SendMixinMessageWorker.perform_async message.stringify_keys
  end
end
