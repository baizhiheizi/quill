# frozen_string_literal: true

class ArticleRewardedNotifier < ApplicationNotifier
  notifies :article_rewarded

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
      [ order.buyer.name.truncate(10), t(".rewarded") ].join(" ")
    end

    def message
      [ order.buyer.name.truncate(10), t(".rewarded"), order.article.title ].join(" ")
    end

    def url
      user_article_url article.author, article.uuid
    end

    def icon_url
      order.buyer.avatar_url
    end

    def should_notify?
      !recipient.block_user? order.buyer
    end
  end
end
