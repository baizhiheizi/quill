# frozen_string_literal: true

module Types
  class MixinNetworkSnapshotType < Types::BaseObject
    field :id, Integer, null: false
    field :trace_id, ID, null: false
    field :snapshot_id, String, null: false
    field :asset_id, String, null: false
    field :user_id, String, null: true
    field :amount, Float, null: false
    field :data, String, null: true
    field :processed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :transferred_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
