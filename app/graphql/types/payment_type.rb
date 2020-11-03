# frozen_string_literal: true

module Types
  class PaymentType < Types::BaseObject
    field :trace_id, ID, null: false
    field :snapshot_id, String, null: false
    field :amount, Float, null: false
    field :memo, String, null: true
    field :state, String, null: false
    field :asset_id, String, null: false

    field :payer, Types::UserType, null: false
    field :order, Types::OrderType, null: true
  end
end
