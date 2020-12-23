# frozen_string_literal: true

class AdminNotificationService
  def text(text)
    message = PrsdiggBot.api.plain_text(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: text
    )
    SendMixinMessageWorker.perform_async message
  end

  def post(post)
    message = PrsdiggBot.api.plain_post(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: post
    )
    SendMixinMessageWorker.perform_async message
  end
end
