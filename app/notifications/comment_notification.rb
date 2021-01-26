# frozen_string_literal: true

class CommentNotification < Noticed::Base
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD'

  param :comment

  def data
    {
      icon_url: Article::PRSDIGG_ICON_URL,
      title: params[:comment].commentable.title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    [params[:comment].author.name, t('.commented')].join(' ')
  end

  def message
    [params[:comment].author.name, t('.commented'), params[:comment].commentable.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s#comment-%<comment_id>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:comment].commentable.uuid,
      comment_id: params[:comment].id
    )
  end
end
