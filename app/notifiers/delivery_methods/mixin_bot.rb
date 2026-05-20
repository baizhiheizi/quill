# frozen_string_literal: true

class DeliveryMethods::MixinBot < Noticed::DeliveryMethod
  def deliver
    I18n.with_locale(recipient&.locale || I18n.default_locale) do
      MixinMessages::SendJob.perform_later format.stringify_keys, bot
    end
  end

  def bot
    if config[:bot] == "RevenueBot" && RevenueBot.api.present?
      "RevenueBot"
    else
      "QuillBot"
    end
  end

  def bot_api
    case bot
    when "RevenueBot"
      RevenueBot.api
    else
      QuillBot.api
    end
  end

  def category
    config[:category] || "PLAIN_TEXT"
  end

  def data
    config[:data] || notification.data
  end

  def conversation_id
    bot_api.unique_conversation_id(recipient.mixin_uuid)
  end

  def format
    bot_api.base_message_params(
      {
        category:,
        conversation_id:,
        recipient_id: recipient.mixin_uuid,
        data:
      }
    )
  end
end
