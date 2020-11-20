# frozen_string_literal: true

module Resolvers
  class AdminTransferConnectionResolver < AdminBaseResolver
    argument :item_id, ID, required: false
    argument :item_type, String, required: false
    argument :source_id, ID, required: false
    argument :source_type, String, required: false
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
      transfers.order(created_at: :desc)
    end
  end
end
