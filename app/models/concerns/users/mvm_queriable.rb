# frozen_string_literal: true

module Users::MVMQueriable
  extend ActiveSupport::Concern

  def tokens_erc721
    return [] unless mvm_eth?

    @tokens_erc721 ||=
      Rails.cache.fetch "#{uid}_tokens_erc721", expires_in: 3.minutes do
        MVM.scan.tokens(uid, type: 'ERC-721')
      end
  end

  def tokens_erc20
    return [] unless mvm_eth?

    @tokens_erc20 ||=
      Rails.cache.fetch "#{uid}_tokens_erc20", expires_in: 3.minutes do
        MVM.scan.tokens(uid, type: 'ERC-20')
      end
  end

  def token_assets
    return unless mvm_eth?

    assets =
      Currency.all.map do |currency|
        TokenAsset.new(
          owner: self,
          currency: currency,
          token: tokens_erc20.find(&->(token) { token['contractAddress'] == currency.mvm_contract_address })
        )
      end

    @token_assets ||=
      assets
      .filter(&->(asset) { asset.balance.positive? || asset.asset_id.in?(Settings.supported_assets) })
      .sort_by(&->(asset) { -asset.balance_usd })
  end
end
