# frozen_string_literal: true

class CommentCreatedNotifier < ApplicationNotifier
  notifies :comment_created

  required_param :comment

  notification_methods do
    def comment
      params[:comment]
    end

    delegate :commentable, to: :comment

    def title
      comment.plain_text.strip
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
  end
end
