# frozen_string_literal: true

class TaggingCreatedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :mixin_bot_notification_enabled?

  param :tagging

  def data
    {
      icon_url: PRSDIGG_ICON_URL,
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
end
