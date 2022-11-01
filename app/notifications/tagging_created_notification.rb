# frozen_string_literal: true

class TaggingCreatedNotification < ApplicationNotification
  deliver_by :database, if: :may_notify_via_web?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :tagging

  def tagging
    params[:tagging]
  end

  delegate :article, to: :tagging

  def data
    {
      icon_url: QUILL_ICON_URL,
      title: tagging.article.title.truncate(36),
      description: description.truncate(72),
      action: url
    }
  end

  def description
    ["##{tagging.tag.name}", t('.has_new_article')].join(' ')
  end

  def message
    ["##{tagging.tag.name}", t('.has_new_article'), params[:tagging].article.title].join(' ')
  end

  def url
    user_article_url article.author, article.uuid
  end

  def should_notify?
    !recipient.block_user? article.author
  end

  def web_notification_enabled?
    recipient.notification_setting.tagging_created_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.tagging_created_mixin_bot
  end

  def may_notify_via_web?
    should_notify? && web_notification_enabled?
  end

  def may_notify_via_mixin_bot?
    should_notify? && recipient_messenger? && mixin_bot_notification_enabled?
  end
end
