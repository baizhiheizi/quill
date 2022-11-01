# frozen_string_literal: true

class ArticlePublishedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :article

  def article
    params[:article]
  end

  def data
    {
      icon_url: icon_url,
      title: article.title.truncate(36),
      description: description.truncate(72),
      action: url
    }
  end

  def description
    [article.author.short_name, t('.published')].join(' ')
  end

  def message
    [article.author.short_name, t('.published'), ':', params[:article].title].join(' ')
  end

  def url
    user_article_url article.author, article.uuid
  end

  def icon_url
    article.author.avatar
  end

  def web_notification_enabled?
    recipient.notification_setting.article_published_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.article_published_mixin_bot
  end

  def may_notify_via_mixin_bot?
    recipient_messenger? && mixin_bot_notification_enabled?
  end
end
