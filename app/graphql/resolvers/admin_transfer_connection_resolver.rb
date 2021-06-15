# frozen_string_literal: true

module Resolvers
  class AdminTransferConnectionResolver < AdminBaseResolver
    argument :item_id, ID, required: false
    argument :item_type, String, required: false
    argument :source_id, ID, required: false
    argument :source_type, String, required: false
    argument :transfer_type, String, required: false
    argument :after, String, required: false

    type Types::TransferConnectionType, null: false

    def resolve(params = {})
      transfers =
        if params[:source_id].present? && params[:source_type].present?
          Object.const_get(params[:source_type]).find(params[:source_id]).transfers
        elsif params[:item_id].present? && params[:item_type].present?
          Object.const_get(params[:item_type]).find(params[:item_id]).transfers
        else
          Transfer.all
        end

      transfers =
        case params[:transfer_type]
        when 'author_revenue'
          transfers.author_revenue
        when 'reader_revenue'
          transfers.reader_revenue
        when 'payment_refund'
          transfers.payment_refund
        when 'prsdigg_revenue'
          transfers.prsdigg_revenue
        when 'bonus'
          transfers.bonus
        when 'swap_change'
          transfers.swap_change
        when 'swap_refund'
          transfers.swap_refund
        when 'fox_swap'
          transfers.fox_swap
        when 'withdraw_balance'
          transfers.withdraw_balance
        else
          transfers
        end

      transfers.order(created_at: :desc)
    end
  end
end
