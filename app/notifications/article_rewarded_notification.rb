# frozen_string_literal: true

class ArticleRewardedNotification < ApplicationNotification
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
    [order.buyer.short_name, t('.rewarded')].join(' ')
  end

  def message
    [order.buyer.short_name, t('.rewarded'), order.article.title].join(' ')
  end

  def url
    user_article_url article.author, article.uuid
  end

  def icon_url
    order.buyer.avatar
  end

  def web_notification_enabled?
    recipient.notification_setting.article_rewarded_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.article_rewarded_mixin_bot
  end

  def may_notify_via_mixin_bot?
    recipient_messenger? && mixin_bot_notification_enabled?
  end
end
