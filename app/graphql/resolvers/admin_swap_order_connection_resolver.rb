# frozen_string_literal: true

module Resolvers
  class AdminSwapOrderConnectionResolver < AdminBaseResolver
    argument :user_id, ID, required: false
    argument :after, String, required: false

    type Types::SwapOrderConnectionType, null: false

    def resolve(params = {})
      user = User.find_by(id: params[:user_id])
      orders =
        if user.present?
          user.swap_orders
        else
          SwapOrder.all
        end
      orders.order(created_at: :desc)
    end
  end
end
