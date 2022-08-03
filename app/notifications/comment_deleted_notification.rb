# frozen_string_literal: true

class CommentDeletedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :comment

  delegate :commentable, to: :comment

  def data
    message
  end

  def message
    [params[:comment].commentable.title, t('deleted')].join(' ')
  end

  def url
    user_article_url commentable.author, commentable.uuid, anchor: "comment_#{comment.id}"
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
