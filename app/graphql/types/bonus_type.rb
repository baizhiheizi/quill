# frozen_string_literal: true

module Types
  class BonusType < Types::BaseObject
    field :id, ID, null: false
    field :trace_id, String, null: false
    field :title, String, null: false
    field :description, String, null: true
    field :amount, Float, null: false
    field :state, String, null: false
    field :asset_id, String, null: false

    field :currency, Types::CurrencyType, null: false
    field :user, Types::UserType, null: false
    field :transfer, Types::TransferType, null: true

    def currency
      BatchLoader::GraphQL.for(object.asset_id).batch do |asset_ids, loader|
        Currency.where(asset_id: asset_ids).each { |currency| loader.call(currency.asset_id, currency) }
      end
    end

    def user
      BatchLoader::GraphQL.for(object.user_id).batch do |user_ids, loader|
        User.where(id: user_ids).each { |user| loader.call(user.id, user) }
      end
    end

    def transfer
      BatchLoader::GraphQL.for(object.id).batch do |ids, loader|
        Transfer.where(source_id: ids, source_type: 'Bonus').each { |transfer| loader.call(transfer.source_id, transfer) }
      end
    end
  end
end
