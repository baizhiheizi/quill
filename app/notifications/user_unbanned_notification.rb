# frozen_string_literal: true

class UserUnbannedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  before_mixin_bot :set_locale

  param :user

  def data
    message
  end

  def message
    t('.unbanned')
  end

  def url
  end

  def set_locale
    I18n.locale = recipient.locale if recipient.locale.present?
  end
end
