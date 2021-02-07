# frozen_string_literal: true

module Types
  class CurrencyType < Types::BaseObject
    field :id, ID, null: false
    field :asset_id, String, null: false
    field :name, String, null: false
    field :symbol, String, null: false
    field :icon_url, String, null: true
    field :chain_id, String, null: true
    field :price_btc, Float, null: true
    field :price_usd, Float, null: true
  end
end
