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
  PRS_ASSET_ID = '3edb734c-6d6f-32ff-ab03-4eb43640c758'
  BTC_ASSET_ID = 'c6d0c728-2624-429b-8e0d-d9d19b6592fa'
  ETH_ASSET_ID = '43d61dcd-e413-450d-80b8-101d5e903357'
  EOS_ASSET_ID = '6cfe566e-4aad-470b-8c9a-2fd35b49c68d'
  MOB_ASSET_ID = 'eea900a8-b327-488c-8d8d-1428702fe240'
  BOX_ASSET_ID = 'f5ef6b5d-cc5a-3d90-b2c0-a2fd386e7a3c'
  USDT_ASSET_ID = '4d8c508b-91c5-375b-92b0-ee702ed2dac5'
  PUSD_ASSET_ID = '31d2ea9c-95eb-3355-b65b-ba096853bc18'
  XIN_ASSET_ID = 'c94ac88f-4671-3976-b60a-09064f1811e8'

  extend OrderAsSpecified

  store :raw, accessors: %i[name symbol chain_id icon_url price_btc price_usd]

  validates :raw, presence: true
  validates :asset_id, presence: true, uniqueness: true

  has_many :articles, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :orders, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :payments, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :transfers, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency

  scope :swappable, -> { where(asset_id: SwapOrder::SUPPORTED_ASSETS).order_as_specified(asset_id: SwapOrder::SUPPORTED_ASSETS) }
  scope :pricable, -> { where(asset_id: Article::SUPPORTED_ASSETS) }
  scope :prs, -> { find_by(asset_id: PRS_ASSET_ID) }
  scope :btc, -> { find_by(asset_id: BTC_ASSET_ID) }

  def self.find_or_create_by_asset_id(_asset_id)
    currency = find_by(asset_id: _asset_id)
    return currency if currency.present?

    r = PrsdiggBot.api.read_asset(_asset_id)
    create_with(raw: r['data']).find_or_create_by(asset_id: r['data']&.[]('asset_id'))
  end

  def swappable?
    SwapOrder::FOXSWAP_ENABLE && asset_id.in?(SwapOrder::SUPPORTED_ASSETS)
  end

  def sync!
    r = PrsdiggBot.api.asset asset_id
    update! raw: r['data']
  end
end
