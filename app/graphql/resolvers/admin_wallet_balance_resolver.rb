# frozen_string_literal: true

module Resolvers
  class AdminWalletBalanceResolver < AdminBaseResolver
    argument :user_id, String, required: false

    type [Types::AssetType], null: false

    def resolve(params = {})
      r = (MixinNetworkUser.find_by(uuid: params[:user_id])&.mixin_api || PrsdiggBot.api).read_assets
      r['data']
    end
  end
end
