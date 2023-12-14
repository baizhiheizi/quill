# frozen_string_literal: true

class UserSafeRegistrationNotification < ApplicationNotification
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :user

  def data
    message
  end

  def message
    t('.message')
  end

  def url
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
