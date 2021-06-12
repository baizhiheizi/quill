# frozen_string_literal: true

class ArticleBlockedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  param :article

  def data
    message
  end

  def message
    [t('.blocked'), params[:article].title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Settings.host,
      article_uuid: params[:article].uuid
    )
  end
end
