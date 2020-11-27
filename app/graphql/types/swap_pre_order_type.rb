# frozen_string_literal: true

module Types
  class SwapPreOrderType < Types::BaseObject
    field :state, String, null: false
    field :funds, Float, null: false
    field :amount, Float, null: false
    field :min_amount, Float, null: false
    field :fill_asset_id, String, null: false
    field :pay_asset_id, String, null: false
    field :price_impact, Float, null: true
    field :route_price, Float, null: true
  end
end
