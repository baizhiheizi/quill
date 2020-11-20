# frozen_string_literal: true

module Resolvers
  class TransferConnectionResolver < BaseResolver
    argument :after, String, required: false

    type Types::TransferConnectionType, null: false

    def resolve(_params = {})
      Transfer.only_user_revenue.order(created_at: :desc)
    end
  end
end
