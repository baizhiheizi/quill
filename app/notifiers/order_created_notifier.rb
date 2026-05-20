# frozen_string_literal: true

class OrderCreatedNotifier < ApplicationNotifier
  deliver_by :mixin_bot, class: "DeliveryMethods::MixinBot" do |config|
    config.category = "PLAIN_TEXT"
    config.if = -> { may_notify_via_mixin_bot? }
  end

  required_param :order

  notification_methods do
    delegate :item, to: :order

    def order
      params[:order]
    end

    def action_name
      case params[:order].order_type.to_sym
      when :buy_article, :buy_collection
        t(".bought")
      when :reward_article
        t(".rewarded")
      end
    end

    def data
      message
    end

    def message
      case order.item
      when Article
        [ action_name, item.title ].join(" ")
      when Collection
        [ action_name, item.name ].join(" ")
      end
    end

    def url
      case order.item
      when Article
        user_article_url item.author, item.uuid
      when Collection
        collection_url item.uuid
      end
    end

    def may_notify_via_mixin_bot?
      recipient_messenger?
    end
  end
end
