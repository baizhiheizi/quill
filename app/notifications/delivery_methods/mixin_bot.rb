# frozen_string_literal: true

class DeliveryMethods::MixinBot < Noticed::DeliveryMethods::Base
  def deliver
    SendMixinMessageWorker.perform_async format
  end

  def category
    options[:category] || 'PLAIN_TEXT'
  end

  def data
    options[:data] || notification.data
  end

  def conversation_id
    PrsdiggBot.api.unique_conversation_id(recipient.mixin_uuid)
  end

  def format
    PrsdiggBot.api.base_message_params(
      {
        category: category,
        conversation_id: conversation_id,
        recipient_id: recipient.mixin_uuid,
        data: data
      }
    )
  end
end
