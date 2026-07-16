# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
# Database name: primary
#
#  id         :bigint           not null, primary key
#  price_btc  :decimal(, )
#  price_usd  :decimal(, )
#  raw        :jsonb
#  symbol     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  chain_id   :uuid
#
# Indexes
#
#  index_currencies_on_asset_id  (asset_id) UNIQUE
#

class Currency < ApplicationRecord
  BTC_ASSET_ID = "c6d0c728-2624-429b-8e0d-d9d19b6592fa"
  ASSET_CACHE_TTL = 30.minutes

  store_accessor :raw, :name, :icon_url, :change_usd

  def icon_url
    url = read_store_attribute(:raw, "icon_url")
    url.presence if url.is_a?(String) && url.match?(%r{\Ahttps?://}i)
  end

  before_validation :set_defaults

  validates :raw, presence: true
  validates :asset_id, presence: true, uniqueness: true

  has_many :articles, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :orders, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :payments, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :transfers, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency

  belongs_to :chain, class_name: "Currency", primary_key: :asset_id, optional: true, inverse_of: false

  scope :pricable, -> { where(asset_id: Article::SUPPORTED_ASSETS) }
  scope :btc, -> { find_by(asset_id: BTC_ASSET_ID) }

  def minimal_reward_amount
    if price_usd.positive?
      BigDecimal(0.5 / price_usd.to_f, 1).ceil(8)
    else
      {
        pUSD: 0.5,
        ETH: 0.0005,
        BTC: 0.00005,
        XIN: 0.005
      }[symbol.to_sym]
    end
  end

  def minimal_price_amount(price = 0.1)
    if price_usd.positive?
      BigDecimal(price.to_f / price_usd, 1).ceil(8)
    else
      {
        pUSD: 0.1,
        ETH: 0.0001,
        BTC: 0.00001,
        XIN: 0.001
      }[symbol.to_sym]
    end
  end

  def pricable?
    asset_id.in? Article::SUPPORTED_ASSETS
  end

  def sync!
    update! asset_id:
  end

  private

  def set_defaults
    if asset_id.present?
      self.raw = fetch_asset_raw
    end

    assign_attributes(
      symbol: raw["symbol"],
      chain_id: raw["chain_id"],
      asset_id: raw["asset_id"],
      price_usd: raw["price_usd"],
      price_btc: raw["price_btc"]
    )
  end

  def fetch_asset_raw
    Rails.cache.fetch(asset_cache_key, expires_in: ASSET_CACHE_TTL, race_condition_ttl: 30.seconds) do
      QuillBot.api.asset(asset_id)["data"]
    end
  rescue MixinBot::Error
    {}
  end

  def asset_cache_key
    "currency:asset:#{asset_id}"
  end
end
