# frozen_string_literal: true

class TaggingCreatedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :tagging

  def data
    {
      icon_url: QUILL_ICON_URL,
      title: params[:tagging].article.title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    ["##{params[:tagging].tag.name}", t('.has_new_article')].join(' ')
  end

  def message
    ["##{params[:tagging].tag.name}", t('.has_new_article'), params[:tagging].article.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Settings.host,
      article_uuid: params[:tagging].article.uuid
    )
  end

  def web_notification_enabled?
    recipient.notification_setting.tagging_created_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.tagging_created_mixin_bot
  end

  def may_notify_via_mixin_bot?
    recipient_messenger? && mixin_bot_notification_enabled?
  end
end
