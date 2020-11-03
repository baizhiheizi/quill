# frozen_string_literal: true

module Resolvers
  class AdminTransferConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::TransferConnectionType, null: false

    def resolve(params = {})
      Transfer.all.order(created_at: :desc)
    end
  end
end
