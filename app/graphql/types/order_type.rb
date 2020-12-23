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
      BatchLoader.for(object.item_id).batch(key: object.item_type) do |ids, loader, args|
        model = Object.const_get(args[:key])
        model.where(id: ids).each { |record| loader.call(record.id, record) }
      end
    end
  end
end
