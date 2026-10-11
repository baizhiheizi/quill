# frozen_string_literal: true

class OrderCreatedNotifier < ApplicationNotifier
  notifies :order_created

  required_param :order

  notification_methods do
    delegate :item, to: :order

    def order
      params[:order]
    end

    def action_name
      case order.order_type.to_sym
      when :buy_article, :buy_collection
        t(".bought")
      when :reward_article
        t(".rewarded")
      end
    end

    def message
      case item
      when Article
        [ action_name, item.title ].join(" ")
      when Collection
        [ action_name, item.name ].join(" ")
      end
    end

    def url
      case item
      when Article
        user_article_url item.author, item.uuid
      when Collection
        collection_url item.uuid
      end
    end
  end
end
