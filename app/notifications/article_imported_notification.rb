# frozen_string_literal: true

class ArticleImportedNotification < ApplicationNotification
  deliver_by :database, if: :web_notification_enabled?

  param :article

  def article
    params[:article]
  end

  def message
    [t('.imported'), ':', params[:article].title].join(' ')
  end

  def url
    edit_article_url article
  end

  def web_notification_enabled?
    recipient.notification_setting.article_published_web
  end
end
