# frozen_string_literal: true

module Resolvers
  class AdminSwapOrderConnectionResolver < AdminBaseResolver
    argument :state, String, required: false
    argument :payer_mixin_uuid, ID, required: false
    argument :after, String, required: false

    type Types::SwapOrderConnectionType, null: false

    def resolve(params = {})
      orders =
        if params[:payer_mixin_uuid].present?
          User.find_by(mixin_uuid: params[:payer_mixin_uuid]).swap_orders
        else
          SwapOrder.all
        end

      orders =
        case params[:state]
        when 'paid'
          orders.paid
        when 'swapping'
          orders.swapping
        when 'rejected'
          orders.rejected
        when 'swapped'
          orders.swapped
        when 'order_placed'
          orders.order_placed
        when 'completed'
          orders.completed
        when 'refunded'
          orders.refunded
        else
          orders
        end

      orders.order(created_at: :desc)
    end
  end
end
