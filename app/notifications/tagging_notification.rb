# frozen_string_literal: true

class TaggingNotification < Noticed::Base
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'APP_CARD'

  param :tagging

  def data
    {
      icon_url: Article::PRSDIGG_ICON_URL,
      title: params[:tagging].article.title.truncate(36),
      description: description,
      action: url
    }
  end

  def description
    ["##{params[:tagging].tag.name}", t('.has_new_article')].join(' ')
  end

  def message
    ["##{params[:tagging].tag.name}", t('.has_new_article'), params[:tagging].article.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:tagging].article.uuid
    )
  end
end
