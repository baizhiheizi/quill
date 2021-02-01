# frozen_string_literal: true

class ArticleBlockedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  before_mixin_bot :set_locale

  param :article

  def data
    message
  end

  def message
    [t('.blocked'), params[:article].title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:article].uuid
    )
  end

  def set_locale
    I18n.locale = recipient.locale if recipient.locale.present?
  end
end
