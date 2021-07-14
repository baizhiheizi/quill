# frozen_string_literal: true

module Types
  class PaymentType < Types::BaseObject
    field :trace_id, ID, null: false
    field :opponent_id, String, null: false
    field :snapshot_id, String, null: false
    field :amount, Float, null: false
    field :memo, String, null: true
    field :decrypted_memo, String, null: true
    field :state, String, null: false
    field :asset_id, String, null: false

    field :payer, Types::UserType, null: true
    field :order, Types::OrderType, null: true
    field :currency, Types::CurrencyType, null: true

    def payer
      BatchLoader::GraphQL.for(object.opponent_id).batch do |opponent_ids, loader|
        User.where(mixin_uuid: opponent_ids).each { |payer| loader.call(payer.mixin_uuid, payer) }
      end
    end

    def order
      BatchLoader::GraphQL.for(object.trace_id).batch do |trace_ids, loader|
        Order.where(trace_id: trace_ids).each { |order| loader.call(order.trace_id, order) }
      end
    end

    def currency
      BatchLoader::GraphQL.for(object.asset_id).batch do |asset_ids, loader|
        Currency.where(asset_id: asset_ids).each { |currency| loader.call(currency.asset_id, currency) }
      end
    end
  end
end
