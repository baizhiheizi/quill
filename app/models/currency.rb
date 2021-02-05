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
  store :raw, accessors: %i[name symbol chain_id icon_url price_btc price_usd]

  validates :raw, presence: true
  validates :asset_id, presence: true, uniqueness: true

  has_many :articles, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :orders, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :payments, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency
  has_many :transfers, primary_key: :asset_id, foreign_key: :asset_id, dependent: :restrict_with_exception, inverse_of: :currency

  scope :swappable, -> { where(asset_id: SwapOrder::SUPPORTED_ASSETS) }
  scope :pricable, -> { where(asset_id: Article::SUPPORTED_ASSETS) }

  def self.find_or_create_by_asset_id(_asset_id)
    currency = find_by(asset_id: _asset_id)
    return currency if currency.present?

    r = PrsdiggBot.api.read_asset(_asset_id)
    create_with(raw: r['data']).find_or_create_by(asset_id: r['data']&.[]('asset_id'))
  end

  def swappable?
    SwapOrder::FOXSWAP_ENABLE && asset_id.in?(SwapOrder::SUPPORTED_ASSETS)
  end
end
