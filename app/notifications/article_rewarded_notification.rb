# frozen_string_literal: true

class ArticleRewardedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :mixin_bot_notification_enabled?

  param :order

  def order
    params[:order]
  end

  def data
    {
      icon_url: order.buyer.avatar,
      title: order.article.title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    [order.buyer.name, t('.rewarded')].join(' ')
  end

  def message
    [order.buyer.name, t('.rewarded'), order.article.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Settings.host,
      article_uuid: order.article.uuid
    )
  end

  def web_notification_enabled?
    recipient.notification_setting.article_rewarded_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.article_rewarded_mixin_bot
  end
end
