# frozen_string_literal: true

module Types
  class OrderType < Types::BaseObject
    field :trace_id, ID, null: false
    field :state, String, null: false
    field :total, Float, null: false

    field :payer, Types::UserType, null: false
    field :receiver, Types::UserType, null: false
    field :item, Types::ArticleType, null: false
  end
end
