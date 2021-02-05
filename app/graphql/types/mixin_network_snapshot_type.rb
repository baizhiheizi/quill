# frozen_string_literal: true

module Types
  class MixinNetworkSnapshotType < Types::BaseObject
    field :id, Integer, null: false
    field :trace_id, ID, null: false
    field :snapshot_id, String, null: false
    field :asset_id, String, null: false
    field :user_id, String, null: false
    field :opponent_id, String, null: true
    field :amount, Float, null: false
    field :data, String, null: true
    field :processed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :transferred_at, GraphQL::Types::ISO8601DateTime, null: false

    field :article, Types::ArticleType, null: true
    field :opponent, Types::UserType, null: true
    field :currency, Types::CurrencyType, null: false

    def article
      BatchLoader::GraphQL.for(object.user_id).batch do |user_ids, loader|
        MixinNetworkUser.includes(:owner).where(uuid: user_ids).each { |user| loader.call(user.uuid, user.owner) if user.owner.is_a?(Article) }
      end
    end

    def opponent
      BatchLoader::GraphQL.for(object.opponent_id).batch do |opponent_ids, loader|
        User.where(mixin_uuid: opponent_ids).each { |opponent| loader.call(opponent.mixin_uuid, opponent) }
      end
    end

    def currency
      BatchLoader::GraphQL.for(object.asset_id).batch do |asset_ids, loader|
        Currency.where(asset_id: asset_ids).each { |currency| loader.call(currency.asset_id, currency) }
      end
    end
  end
end
