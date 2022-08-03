# frozen_string_literal: true

class ArticleUnblockedNotification < ApplicationNotification
  deliver_by :database
  deliver_by :mixin_bot, class: 'DeliveryMethods::MixinBot', category: 'PLAIN_TEXT', if: :may_notify_via_mixin_bot?

  param :article

  def article
    params[:article]
  end

  def data
    message
  end

  def message
    [t('.unblocked'), params[:article].title].join(' ')
  end

  def url
    user_article_url article.author, article.uuid
  end

  def may_notify_via_mixin_bot?
    recipient_messenger?
  end
end
