# frozen_string_literal: true

module Mutations
  class AdminWithdrawBalanceMutation < AdminBaseMutation
    argument :asset_id, String, required: true
    argument :amount, String, required: true

    type Boolean

    def resolve(**params)
      balance = PrsdiggBot.api.asset(params[:asset_id])['balance']
      return if params[:amount].to_f > balance.to_f

      Transfer.create!(
        transfer_type: :withdraw_balance,
        opponent_id: PrsdiggBot.api.me['app']['creator_id'],
        asset_id: params[:asset_id],
        amount: params[:amount],
        memo: 'WITHDRAW BALANCE',
        trace_id: SecureRandom.uuid
      )
    end
  end
end
