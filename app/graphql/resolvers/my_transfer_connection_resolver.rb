# frozen_string_literal: true

module Resolvers
  class MyTransferConnectionResolver < MyBaseResolver
    argument :after, String, required: false
    argument :transfer_type, String, required: false

    type Types::TransferConnectionType, null: false

    def resolve(params = {})
      transfers =
        case params[:transfer_type]
        when 'author_revenue'
          current_user.author_revenue_transfers
        when 'reader_revenue'
          current_user.reader_revenue_transfers
        else
          current_user.transfers
        end
      transfers.order(created_at: :desc)
    end
  end
end
