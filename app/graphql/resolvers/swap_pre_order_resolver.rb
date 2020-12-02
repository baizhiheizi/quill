# frozen_string_literal: true

module Resolvers
  class SwapPreOrderResolver < BaseResolver
    argument :pay_asset_id, String, required: true
    argument :amount, Float, required: true

    type Types::SwapPreOrderType, null: true

    def resolve(params)
      return if params[:pay_asset_id] == Article::PRS_ASSET_ID

      r = Foxswap.api.pre_order(
        pay_asset_id: params[:pay_asset_id],
        fill_asset_id: Article::PRS_ASSET_ID,
        amount: params[:amount]
      )

      r['data']
    end
  end
end
