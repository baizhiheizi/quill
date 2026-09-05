# frozen_string_literal: true

class ArticlePublishedNotifier < ApplicationNotifier
  notifies :article_published

  required_param :article

  notification_methods do
    def article
      params[:article]
    end

    def title
      article.title
    end

    def description
      [ article.author.name.truncate(10), t(".published") ].join(" ")
    end

    def message
      [ article.author.name.truncate(10), t(".published"), ":", article.title ].join(" ")
    end

    def url
      user_article_url article.author, article.uuid
    end

    def icon_url
      article.author.avatar_url
    end
  end
end
