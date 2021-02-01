# frozen_string_literal: true

class ReadingSubscribeActionCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  before_mixin_bot :set_locale

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
      host: Rails.application.credentials.fetch(:host),
      mixin_id: params[:action].user.mixin_id
    )
  end

  def set_locale
    I18n.locale = recipient.locale if recipient.locale.present?
  end
end
