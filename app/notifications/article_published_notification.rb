# frozen_string_literal: true

class ArticlePublishedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD'

  param :article

  def data
    {
      icon_url: Article::PRSDIGG_ICON_URL,
      title: params[:article].title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    [params[:article].author.name, t('.published')].join(' ')
  end

  def message
    [params[:article].author.name, t('.published'), params[:article].title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:article].uuid
    )
  end
end
