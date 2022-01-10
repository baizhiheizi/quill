# frozen_string_literal: true

module Admin
  class SwapOrdersController < Admin::BaseController
    def index
      swap_orders = SwapOrder.all.includes(payment: :payer)
      swap_orders = swap_orders.where(payments: { payer_id: params[:payer_id] }) if params[:payer_id].present?

      @state = params[:state] || 'all'
      swap_orders =
        case @state
        when 'all'
          swap_orders
        else
          swap_orders.where(state: @state)
        end

      @order_by = params[:order_by] || 'created_at_desc'
      swap_orders =
        case @order_by
        when 'created_at_desc'
          swap_orders.order(created_at: :desc)
        when 'created_at_asc'
          swap_orders.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      swap_orders =
        swap_orders.ransack(
          {
            id_eq: @query,
            user_id_eq: @query,
            trace_id_eq: @query,
            pay_asset_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @swap_orders = pagy_countless swap_orders
    end

    def show
      @tab = params[:tab] || 'transfers'
      @swap_order = SwapOrder.find params[:id]
    end
  end
end
