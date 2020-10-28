# frozen_string_literal: true

module Resolvers
  class MyTransferConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::TransferConnectionType, null: false

    def resolve(_params = {})
      current_user.transfers
    end
  end
end
