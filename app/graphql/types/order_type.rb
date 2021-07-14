# frozen_string_literal: true

module Types
  class OrderType < Types::BaseObject
    field :id, ID, null: false
    field :trace_id, ID, null: false
    field :state, String, null: false
    field :order_type, String, null: false
    field :total, Float, null: false
    field :item_id, ID, null: false
    field :item_type, String, null: false

    field :buyer, Types::UserType, null: false
    field :seller, Types::UserType, null: false
    field :item, Types::OrderItemUnion, null: false
    field :citer, Types::OrderItemUnion, null: true
    field :currency, Types::CurrencyType, null: false

    def buyer
      BatchLoader::GraphQL.for(object.buyer_id).batch do |buyer_ids, loader|
        User.where(id: buyer_ids).each { |buyer| loader.call(buyer.id, buyer) }
      end
    end

    def seller
      BatchLoader::GraphQL.for(object.seller_id).batch do |seller_ids, loader|
        User.where(id: seller_ids).each { |seller| loader.call(seller.id, seller) }
      end
    end

    def item
      BatchLoader::GraphQL.for(object.item_id).batch(key: object.item_type) do |ids, loader, args|
        model = Object.const_get(args[:key])
        model.where(id: ids).each { |record| loader.call(record.id, record) }
      end
    end

    def currency
      BatchLoader::GraphQL.for(object.asset_id).batch do |asset_ids, loader|
        Currency.where(asset_id: asset_ids).each { |currency| loader.call(currency.asset_id, currency) }
      end
    end
  end
end
