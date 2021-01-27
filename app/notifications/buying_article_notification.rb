# frozen_string_literal: true

class BuyingArticleNotification < Noticed::Base
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD'

  param :order

  def data
    {
      icon_url: Article::PRSDIGG_ICON_URL,
      title: params[:order].article.title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    [params[:order].buyer.name, t('.bought')].join(' ')
  end

  def message
    [params[:order].buyer.name, t('.bought'), params[:order].article.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:order].article.uuid
    )
  end
end
