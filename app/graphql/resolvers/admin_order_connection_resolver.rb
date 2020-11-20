# frozen_string_literal: true

module Resolvers
  class AdminOrderConnectionResolver < AdminBaseResolver
    argument :item_id, ID, required: false
    argument :item_type, String, required: false
    argument :after, String, required: false

    type Types::OrderConnectionType, null: false

    def resolve(params)
      orders =
        if params[:item_id].present? && params[:item_type].present?
          Object.const_get(params[:item_type]).find_by(id: params[:item_id]).orders
        else
          Order.all
        end
      orders.order(created_at: :desc)
    end
  end
end
