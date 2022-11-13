# frozen_string_literal: true

class CommentCreatedNotification < ApplicationNotification
  deliver_by :database, if: :may_notify_via_web?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :may_notify_via_mixin_bot?

  param :comment

  def comment
    params[:comment]
  end

  delegate :commentable, to: :comment

  def data
    {
      icon_url: icon_url,
      title: comment.content.gsub(/^(>\s)+(.)*$/, '').strip.truncate(36),
      description: description.truncate(72),
      action: url
    }
  end

  def description
    message
  end

  def message
    [comment.author.name, t('.commented'), commentable.title].join(' ')
  end

  def icon_url
    comment.author.avatar_thumb
  end

  def url
    user_article_url commentable.author, commentable.uuid, anchor: "comment_#{comment.id}"
  end

  def should_notify?
    !recipient.block_user? comment.author
  end

  def web_notification_enabled?
    recipient.notification_setting.comment_created_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.comment_created_mixin_bot
  end

  def may_notify_via_web?
    should_notify? && web_notification_enabled?
  end

  def may_notify_via_mixin_bot?
    should_notify? && recipient_messenger? && mixin_bot_notification_enabled?
  end
end
