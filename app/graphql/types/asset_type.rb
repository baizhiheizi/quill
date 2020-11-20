# frozen_string_literal: true

module Types
  class AssetType < Types::BaseObject
    field :asset_id, ID, null: false
    field :chain_id, ID, null: true
    field :symbol, String, null: true
    field :name, String, null: true
    field :icon_url, String, null: true
    field :balance, String, null: true
    field :price_btc, String, null: true
    field :price_usd, String, null: true
    field :change_usd, String, null: true
    field :change_btc, String, null: true
  end
end
