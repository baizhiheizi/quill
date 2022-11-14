# frozen_string_literal: true

module Admin
  class PreOrdersController < Admin::BaseController
    def index
      pre_orders = PreOrder.all

      pre_orders = pre_orders.where(payer_id: params[:payer_id]) if params[:payer_id].present?
      pre_orders = pre_orders.where(item_id: params[:item_id], item_type: params[:item_type]) if params[:item_id].present? && params[:item_type].present?

      @state = params[:state] || 'all'
      pre_orders =
        case @state
        when 'all'
          pre_orders
        else
          pre_orders.where(state: @state)
        end

      @order_type = params[:order_type] || 'all'
      pre_orders =
        case @order_type
        when 'all'
          pre_orders
        else
          pre_orders.where(order_type: @order_type)
        end

      @order_by = params[:order_by] || 'created_at_desc'
      pre_orders =
        case @order_by
        when 'created_at_desc'
          pre_orders.order(created_at: :desc)
        when 'created_at_asc'
          pre_orders.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      pre_orders =
        pre_orders.ransack(
          {
            id_eq: @query,
            buyer_id_eq: @query,
            trace_id_eq: @query,
            asset_id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @pre_orders = pagy_countless pre_orders
    end

    def show
      @pre_order = PreOrder.find_by follow_id: params[:follow_id]
    end
  end
end
