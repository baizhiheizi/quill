# frozen_string_literal: true

class AuthoringSubscribeActionCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  param :action

  def data
    message
  end

  def message
    [params[:action].user.name, t('.subscribed')].join(' ')
  end

  def url
    format(
      '%<host>s/users/%<mixin_id>s',
      host: Settings.host,
      mixin_id: params[:action].user.mixin_id
    )
  end
end
