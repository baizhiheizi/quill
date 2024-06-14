# frozen_string_literal: true

module Admin
  class WalletsController < Admin::BaseController
    before_action :load_wallet

    def assets
      @assets = @wallet.assets['data']
    end

    def snapshots
      limit = 25
      @snapshots = @wallet.snapshots(limit:, offset: params[:offset])['data']
      @has_next = @snapshots.size >= limit
    end

    def safe_outputs
      limit = 100
      @safe_outputs = @wallet.safe_outputs(limit:, state: :unspent, offset: params[:offset])['data']
      @has_next = @safe_outputs.size >= limit
    end

    private

    def load_wallet
      @wallet =
        if params[:wallet_id] == QuillBot.api.client_id
          QuillBot.api
        elsif MixinNetworkUser.find_by(uuid: params[:wallet_id])
          MixinNetworkUser.find_by(uuid: params[:wallet_id]).mixin_api
        end
      raise 'Wallet nof found' if @wallet.blank?
    end
  end
end
