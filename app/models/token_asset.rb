# frozen_string_literal: true

class TokenAsset
  attr_reader :owner, :token, :currency, :contract, :balance, :balance_usd, :asset_id, :chain_id, :chain, :symbol, :price_btc, :price_usd, :change_usd

  delegate :asset_id, :chain_id, :chain, :symbol, :name, :icon_url, :price_btc, :price_usd, :change_usd, to: :currency

  def initialize(owner:, token:, currency: nil)
    @owner = owner
    @currency = currency
    @token = token
    @balance =
      if token.present?
        (token['balance'].to_r / (10**token['decimals'].to_i)).to_f.round(8)
      else
        0
      end
    @balance_usd = (@balance * currency.price_usd.to_f).round(4)
  end
end
