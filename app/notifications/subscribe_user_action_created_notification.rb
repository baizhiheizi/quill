# frozen_string_literal: true

class SubscribeUserActionCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :action

  def data
    message
  end

  def message
    [params[:action].user.short_name, t('.subscribed')].join(' ')
  end

  def url
    user_url params[:action].user.uid
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
