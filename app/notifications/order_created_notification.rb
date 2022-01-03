# frozen_string_literal: true

class OrderCreatedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

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
      host: Settings.host,
      article_uuid: params[:order].article.uuid
    )
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
