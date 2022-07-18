# frozen_string_literal: true

class DeliveryMethods::MixinBot < Noticed::DeliveryMethods::Base
  def deliver
    SendMixinMessageWorker.perform_async format, bot
  end

  def bot
    if options[:bot] == 'RevenueBot' && RevenueBot.api.present?
      'RevenueBot'
    else
      'BatataBot'
    end
  end

  def bot_api
    case bot
    when 'RevenueBot'
      RevenueBot.api
    else
      BatataBot.api
    end
  end

  def category
    options[:category] || 'PLAIN_TEXT'
  end

  def data
    options[:data] || notification.data
  end

  def conversation_id
    bot_api.unique_conversation_id(recipient.mixin_uuid)
  end

  def format
    bot_api.base_message_params(
      {
        category: category,
        conversation_id: conversation_id,
        recipient_id: recipient.mixin_uuid,
        data: data
      }
    )
  end
end
