# frozen_string_literal: true

class OrderCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT'

  before_mixin_bot :set_locale

  param :order

  def action_name
    case params[:order].order_type.to_sym
    when :buy_article
      t('.bought')
    when :reward_article
      t('.rewarded')
    end
  end

  def data
    message
  end

  def message
    [action_name, params[:order].article.title].join(' ')
  end

  def url
    format(
      '%<host>s/articles/%<article_uuid>s',
      host: Rails.application.credentials.fetch(:host),
      article_uuid: params[:order].article.uuid
    )
  end

  def set_locale
    I18n.locale = recipient.locale if recipient.locale.present?
  end
end
