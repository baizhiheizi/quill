# frozen_string_literal: true

class UserUnbannedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :user

  def data
    message
  end

  def message
    t('.unbanned')
  end

  def url
  end
end
