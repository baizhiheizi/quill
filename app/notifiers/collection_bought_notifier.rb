# frozen_string_literal: true

class CollectionBoughtNotifier < ApplicationNotifier
  notifies :collection_bought

  required_param :order

  notification_methods do
    def order
      params[:order]
    end

    def collection
      order.item
    end

    def title
      collection.name
    end

    def description
      [ order.buyer.name.truncate(10), t(".bought") ].join(" ")
    end

    def message
      [ order.buyer.name.truncate(10), t(".bought"), ":", collection.name ].join(" ")
    end

    def icon_url
      order.buyer.avatar_url
    end

    def url
      collection_url collection.uuid
    end

    def should_notify?
      !recipient.block_user? order.buyer
    end
  end
end
