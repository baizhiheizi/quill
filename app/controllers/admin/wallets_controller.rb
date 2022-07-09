# frozen_string_literal: true

module Admin
  class WalletsController < Admin::BaseController
    before_action :load_wallet

    def assets
      @assets = @wallet.assets['data']
    end

    def snapshots
      limit = 25
      @snapshots = @wallet.snapshots(limit: limit, offset: params[:offset])['data']
      @has_next = @snapshots.size >= limit
    end

    private

    def load_wallet
      @wallet =
        if params[:wallet_id] == BatataBot.api.client_id
          BatataBot.api
        elsif MixinNetworkUser.find_by(uuid: params[:wallet_id])
          MixinNetworkUser.find_by(uuid: params[:wallet_id]).mixin_api
        end
      raise 'Wallet nof found' if @wallet.blank?
    end
  end
end
