# frozen_string_literal: true

class Dashboard::AssetsController < Dashboard::BaseController
  def index
    @tab =
      if current_user.mvm_eth?
        params[:tab] || 'token'
      else
        'nft'
      end

    case @tab
    when 'token'
      @token_assets = current_user.token_assets
    when 'NFT'
      @nft_collections = current_user.owning_collections
    end
  end
end
