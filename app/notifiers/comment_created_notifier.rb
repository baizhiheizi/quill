# frozen_string_literal: true

class CommentCreatedNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "APP_CARD"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :comment

  notification_methods do
    def comment
      params[:comment]
    end

    delegate :commentable, to: :comment

    def data
      {
        icon_url:,
        title: comment.plain_text.strip.truncate(36),
        description: description.truncate(72),
        action: url
      }
    end

    def description
      message
    end

    def message
      [ comment.author.name.truncate(10), t(".commented"), commentable.title ].join(" ")
    end

    def icon_url
      comment.author.avatar_url
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
end
