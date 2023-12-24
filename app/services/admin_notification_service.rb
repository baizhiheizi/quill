# frozen_string_literal: true

class AdminNotificationService
  def text(text)
    return if Rails.application.credentials.dig(:admin, :group_conversation_id).blank?

    message = QuillBot.api.plain_text(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: text
    )
    MixinMessages::SendJob.perform_later message.stringify_keys
  end

  def post(post)
    message = QuillBot.api.plain_post(
      conversation_id: Rails.application.credentials.dig(:admin, :group_conversation_id),
      data: post
    )
    MixinMessages::SendJob.perform_later message.stringify_keys
  end
end
