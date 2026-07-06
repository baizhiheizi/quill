# frozen_string_literal: true

module Admin
  class OrdersController < Admin::BaseController
    def index
      orders = Order.all

      orders = orders.where(buyer_id: params[:buyer_id]) if params[:buyer_id].present?
      orders = orders.where(item_id: params[:item_id], item_type: params[:item_type]) if params[:item_id].present? && params[:item_type].present?

      @state = params[:state] || "all"
      orders =
        case @state
        when "all"
          orders
        else
          orders.where(state: @state)
        end

      @order_by = params[:order_by] || "created_at_desc"
      orders =
        case @order_by
        when "created_at_desc"
          orders.order(created_at: :desc)
        when "created_at_asc"
          orders.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      orders =
        orders.ransack(
          {
            id_eq: @query,
            buyer_id_eq: @query,
            trace_id_eq: @query,
            asset_id_eq: @query
          }.merge(m: "or")
        ).result

      # Eager-load associations consumed by the rendered partial
      # `app/views/admin/orders/_order.html.erb`:
      #   - `:item`   → `case order.item` (polymorphic Article/Collection).
      #     Rails 7+ groups preloaded polymorphic rows by `item_type` and
      #     fires one SELECT per type instead of one per row.
      #   - `:buyer`  → `order.buyer` plus avatar fallback data
      #     (admin/users/_field.html.erb)
      #   - `:currency` → `order.currency.icon_url`, `order.price_tag`
      #
      # Without these includes each row triggers ~3 SELECTs (item + buyer +
      # currency). For an admin viewing a pagy page of 50 orders, the
      # action runs ~150 SELECTs per request.
      @pagy, @orders = pagy(:countless, orders.includes(:item, :currency, buyer: admin_user_field_preloads))
    end

    def show
      @order = Order.find params[:id]
    end
  end
end
