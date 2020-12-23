# frozen_string_literal: true

module Resolvers
  class MySwapOrderConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::SwapOrderConnectionType, null: false

    def resolve(_params = {})
      current_user.swap_orders.order(created_at: :desc)
    end
  end
end
