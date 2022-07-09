# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
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
  BTC_ASSET_ID = 'c6d0c728-2624-429b-8e0d-d9d19b6592fa'
  JPYC_ASSET_ID = '0ff3f325-4f34-334d-b6c0-a3bd8850fc06'
  PUSD_ASSET_ID = '31d2ea9c-95eb-3355-b65b-ba096853bc18'
  XIN_ASSET_ID = 'c94ac88f-4671-3976-b60a-09064f1811e8'
  ETH_ASSET_ID = '43d61dcd-e413-450d-80b8-101d5e903357'

  store :raw, accessors: %i[name icon_url]

  before_validation :set_defaults

  validates :raw, presence: true
  validates :asset_id, presence: true, uniqueness: true

  has_many :articles, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :orders, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :payments, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :transfers, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency

  belongs_to :chain, class_name: 'Currency', primary_key: :asset_id, optional: true, inverse_of: false

  scope :swappable, -> { where(asset_id: SwapOrder::SWAPABLE_ASSETS).order(symbol: :asc) }
  scope :pricable, -> { where(asset_id: Article::SUPPORTED_ASSETS) }
  scope :btc, -> { find_by(asset_id: BTC_ASSET_ID) }

  def minimal_reward_amount
    BigDecimal(0.5 / price_usd.to_f, 1).to_f
  end

  def minimal_price_amount
    BigDecimal(0.1 / price_usd.to_f, 1).to_f
  end

  def swappable?
    asset_id.in? SwapOrder::SWAPABLE_ASSETS
  end

  def pricable?
    asset_id.in? Article::SUPPORTED_ASSETS
  end

  def sync!
    r = BatataBot.api.asset asset_id
    update! raw: r['data']
  end

  def swap(fill_asset_id, amount)
    Foxswap.api.pre_order(
      pay_asset_id: asset_id,
      fill_asset_id: fill_asset_id,
      funds: (amount * 1.01).round(8).to_r.to_f
    )['data']['amount']
  end

  private

  def set_defaults
    if raw.blank? && asset_id.present?
      self.raw =
        begin
          BatataBot.api.asset(asset_id)['data']
        rescue MixinBot::Error
          {}
        end
    end

    assign_attributes(
      symbol: raw['symbol'],
      chain_id: raw['chain_id'],
      asset_id: raw['asset_id'],
      price_usd: raw['price_usd'],
      price_btc: raw['price_btc']
    )
  end
end
