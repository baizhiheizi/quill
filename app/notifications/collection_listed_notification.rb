# frozen_string_literal: true

class CollectionListedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :collection

  def collection
    params[:collection]
  end

  def data
    {
      icon_url: icon_url,
      title: collection.name.truncate(36),
      description: description.truncate(72),
      action: url
    }
  end

  def description
    [collection.author.name, t('.listed')].join(' ')
  end

  def message
    [collection.author.name, t('.listed'), ':', collection.name].join(' ')
  end

  def url
    collection_url collection.uuid
  end

  def icon_url
    collection.author.avatar_thumb
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
