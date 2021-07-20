# frozen_string_literal: true

class CommentCreatedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD', if: :mixin_bot_notification_enabled?

  param :comment

  def comment
    params[:comment]
  end

  def data
    {
      icon_url: comment.author.avatar,
      title: comment.content.gsub(/^(>\s)+(.)*$/, '').strip.truncate(36),
      description: description.truncate(25),
      action: url
    }
  end

  def description
    message
  end

  def message
    [comment.author.name, t('.commented'), comment.commentable.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s#comment-%<comment_id>s',
      host: Settings.host,
      article_uuid: comment.commentable.uuid,
      comment_id: comment.id
    )
  end

  def web_notification_enabled?
    recipient.notification_setting.comment_created_web
  end

  def mixin_bot_notification_enabled?
    recipient.notification_setting.comment_created_mixin_bot
  end
end
