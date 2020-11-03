# frozen_string_literal: true

module Types
  class OrderType < Types::BaseObject
    field :trace_id, ID, null: false
    field :state, String, null: false
    field :order_type, String, null: false
    field :total, Float, null: false

    field :buyer, Types::UserType, null: false
    field :seller, Types::UserType, null: false
    field :item, Types::ArticleType, null: false
  end
end
