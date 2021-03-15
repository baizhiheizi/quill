# frozen_string_literal: true

class DeliveryMethods::MixinBot < Noticed::DeliveryMethods::Base
  around_deliver :with_locale

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

  def with_locale(&action)
    locale = recipient&.locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
