# frozen_string_literal: true

class ArticlePublishedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :mixin_bot_notification_enabled?

  before_mixin_bot :set_locale

  param :article

  def data
    {
      icon_url: PRSDIGG_ICON_URL,
      title: params[:article].title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    [params[:article].author.name, t('.published')].join(' ')
  end

  def message
    [params[:article].author.name, t('.published'), params[:article].title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:article].uuid
    )
  end

  def web_notification_enabled?
    recipient.notification_setting.article_published_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.article_published_mixin_bot
  end

  def set_locale
    I18n.locale = recipient.locale if recipient.locale.present?
  end
end
