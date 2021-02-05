# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
#
#  id         :bigint           not null, primary key
#  raw        :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#
# Indexes
#
#  index_currencies_on_asset_id  (asset_id) UNIQUE
#
class Currency < ApplicationRecord
  # PRS: 3edb734c-6d6f-32ff-ab03-4eb43640c758
  # BTC: c6d0c728-2624-429b-8e0d-d9d19b6592fa
  # ETH: 43d61dcd-e413-450d-80b8-101d5e903357
  # EOS: 6cfe566e-4aad-470b-8c9a-2fd35b49c68d
  # pUSD: 31d2ea9c-95eb-3355-b65b-ba096853bc18
  # XIN: c94ac88f-4671-3976-b60a-09064f1811e8
  # supported for swap
  SUPPORTED = %w[
    3edb734c-6d6f-32ff-ab03-4eb43640c758
    c6d0c728-2624-429b-8e0d-d9d19b6592fa
    43d61dcd-e413-450d-80b8-101d5e903357
    6cfe566e-4aad-470b-8c9a-2fd35b49c68d
    31d2ea9c-95eb-3355-b65b-ba096853bc18
    c94ac88f-4671-3976-b60a-09064f1811e8
  ].freeze

  store :raw, accessors: %i[name symbol chain_id icon_url price_btc price_usd]

  validates :raw, presence: true
  validates :asset_id, presence: true, uniqueness: true

  has_many :articles, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :orders, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :payments, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :transfers, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency

  scope :supported, -> { where(asset_id: SUPPORTED) }

  def self.find_or_create_by_asset_id(_asset_id)
    currency = find_by(asset_id: _asset_id)
    return currency if currency.present?

    r = PrsdiggBot.api.read_asset(_asset_id)
    create_with(raw: r['data']).find_or_create_by(asset_id: r['data']&.[]('asset_id'))
  end
end
