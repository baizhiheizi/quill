# frozen_string_literal: true

class Dashboard::AssetsController < Dashboard::BaseController
  def index
    @tab =
      if current_user.mvm_eth?
        params[:tab] || 'token'
      else
        params[:tab] || 'nft'
      end

    case @tab
    when 'token'
      @token_assets = current_user.token_assets
    when 'nft'
      @collectibles = current_user.owning_collectibles.includes(:nft_collection)
      current_user.sync_collectibles_async
    end
  end
end
