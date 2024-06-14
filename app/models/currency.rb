# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
#
#  id                   :bigint           not null, primary key
#  mvm_contract_address :string
#  price_btc            :decimal(, )
#  price_usd            :decimal(, )
#  raw                  :jsonb
#  symbol               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  asset_id             :uuid
#  chain_id             :uuid
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

  store :raw, accessors: %i[name icon_url change_usd]

  before_validation :set_defaults

  validates :raw, presence: true
  validates :asset_id, presence: true, uniqueness: true

  has_many :articles, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :orders, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :payments, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency
  has_many :transfers, primary_key: :asset_id, foreign_key: :asset_id, dependent: :nullify, inverse_of: :currency

  belongs_to :chain, class_name: 'Currency', primary_key: :asset_id, optional: true, inverse_of: false

  scope :swappable, -> { where(asset_id: swappable_asset_ids).order(symbol: :asc) }
  scope :pricable, -> { where(asset_id: Article::SUPPORTED_ASSETS) }
  scope :btc, -> { find_by(asset_id: BTC_ASSET_ID) }

  def self.pando_lake_pairs
    Rails.cache.fetch 'pando_lake_routes', expires_in: 5.seconds do
      PandoLake.api.pairs['data']['pairs']
    end
  rescue StandardError
    []
  end

  # disable swappable for now
  def self.swappable_asset_ids
    []
    # Rails.cache.fetch 'swappable_asset_ids', expires_in: 1.hour do
    #   pando_lake_pairs
    #     .filter(&lambda { |p|
    #       (p['base_value'].to_f + p['quote_value'].to_f > 50_000) || p['swap_method'] == 'curve'
    #     }).map do |p|
    #     [p['base_asset_id'], p['quote_asset_id']]
    #   end.flatten.uniq
    # end
  end

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

  def swappable?
    asset_id.in? self.class.swappable_asset_ids
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
      self.raw =
        begin
          QuillBot.api.asset(asset_id)['data']
        rescue MixinBot::Error
          {}
        end
      self.mvm_contract_address = MVM.registry.contract_from_asset asset_id
    elsif mvm_contract_address.present?
      self.asset_id = MVM.registry.asset_from_contract mvm_contract_address
      self.raw =
        begin
          QuillBot.api.asset(asset_id)['data']
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
