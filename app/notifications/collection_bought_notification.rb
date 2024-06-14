# frozen_string_literal: true

class CollectionBoughtNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :order

  def order
    params[:order]
  end

  def collection
    order.item
  end

  def data
    {
      icon_url:,
      title: collection.name.truncate(36),
      description: description.truncate(72),
      action: url
    }
  end

  def description
    [order.buyer.name.truncate(10), t('.bought')].join(' ')
  end

  def message
    [order.buyer.name.truncate(10), t('.bought'), ':', collection.name].join(' ')
  end

  def icon_url
    order.buyer.avatar_url
  end

  def url
    collection_url collection.uuid
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
