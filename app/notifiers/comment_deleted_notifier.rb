# frozen_string_literal: true

class CommentDeletedNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "PLAIN_TEXT"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :comment

  notification_methods do
    def comment
      params[:comment]
    end

    delegate :commentable, to: :comment

    def data
      message
    end

    def message
      [ params[:comment].commentable.title, t(".deleted") ].join(" ")
    end

    def url
      user_article_url commentable.author, commentable.uuid, anchor: "comment_#{comment.id}"
    end

    def may_notify_via_mixin_bot?
      recipient_messenger?
    end
  end
end
