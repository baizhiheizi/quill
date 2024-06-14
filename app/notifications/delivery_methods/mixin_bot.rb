# frozen_string_literal: true

class DeliveryMethods::MixinBot < Noticed::DeliveryMethods::Base
  around_deliver :with_locale

  def deliver
    MixinMessages::SendJob.perform_later format.stringify_keys, bot
  end

  def bot
    if options[:bot] == 'RevenueBot' && RevenueBot.api.present?
      'RevenueBot'
    else
      'QuillBot'
    end
  end

  def bot_api
    case bot
    when 'RevenueBot'
      RevenueBot.api
    else
      QuillBot.api
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
        category:,
        conversation_id:,
        recipient_id: recipient.mixin_uuid,
        data:
      }
    )
  end

  def with_locale(&)
    locale = recipient&.locale || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
