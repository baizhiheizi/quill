# frozen_string_literal: true

class ArticleBoughtNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :order

  delegate :article, to: :order

  def order
    params[:order]
  end

  def data
    {
      icon_url: icon_url,
      title: order.article.title.truncate(36),
      description: description.truncate(72),
      action: url
    }
  end

  def description
    [order.buyer.short_name, t('.bought')].join(' ')
  end

  def message
    [order.buyer.short_name, t('.bought'), ':', order.article.title].join(' ')
  end

  def icon_url
    order.buyer.avatar_thumb
  end

  def url
    user_article_url article.author, article.uuid
  end

  def web_notification_enabled?
    recipient.notification_setting.article_bought_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.article_bought_mixin_bot
  end

  def may_notify_via_mixin_bot?
    recipient_messenger? && mixin_bot_notification_enabled?
  end
end
