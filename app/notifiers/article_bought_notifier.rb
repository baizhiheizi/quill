# frozen_string_literal: true

class ArticleBoughtNotifier < ApplicationNotifier
  notifies :article_bought

  required_param :order

  notification_methods do
    delegate :article, to: :order

    def order
      params[:order]
    end

    def title
      order.article.title
    end

    def description
      [ order.buyer.name.truncate(10), t(".bought") ].join(" ")
    end

    def message
      [ order.buyer.name.truncate(10), t(".bought"), ":", order.article.title ].join(" ")
    end

    def icon_url
      order.buyer.avatar_url
    end

    def url
      user_article_url article.author, article.uuid
    end

    def should_notify?
      !recipient.block_user? order.buyer
    end
  end
end
