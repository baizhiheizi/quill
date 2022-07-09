# frozen_string_literal: true

class AdminNotificationService
  def text(text)
    return if Rails.application.credentials.dig(:admin, :group_conversation_id).blank?

    message = BatataBot.api.plain_text(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: text
    )
    SendMixinMessageWorker.perform_async message
  end

  def post(post)
    message = BatataBot.api.plain_post(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: post
    )
    SendMixinMessageWorker.perform_async message
  end
end
