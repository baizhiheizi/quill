# frozen_string_literal: true

module Admin
  class PreOrdersController < Admin::BaseController
    def index
      pre_orders = PreOrder.all

      pre_orders = pre_orders.where(payer_id: params[:payer_id]) if params[:payer_id].present?
      pre_orders = pre_orders.where(item_id: params[:item_id], item_type: params[:item_type]) if params[:item_id].present? && params[:item_type].present?

      @state = params[:state] || "all"
      pre_orders =
        case @state
        when "all"
          pre_orders
        else
          pre_orders.where(state: @state)
        end

      @order_type = params[:order_type] || "all"
      pre_orders =
        case @order_type
        when "all"
          pre_orders
        else
          pre_orders.where(order_type: @order_type)
        end

      @order_by = params[:order_by] || "created_at_desc"
      pre_orders =
        case @order_by
        when "created_at_desc"
          pre_orders.order(created_at: :desc)
        when "created_at_asc"
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
          }.merge(m: "or")
        ).result

      # Eager-load associations consumed by the rendered partial
      # `app/views/admin/pre_orders/_pre_order.html.erb`:
      #   - `:item`     → `case pre_order.item` (polymorphic
      #     Article/Collection; Rails 7+ groups preloaded rows by
      #     `item_type` and fires one SELECT per type).
      #   - `payer: admin_user_field_preloads` → `render "admin/users/field",
      #     user: pre_order.payer` → `shared/_avatar` with `thumb: true` →
      #     `user.avatar_image_thumb` walks the ActiveStorage
      #     `:avatar_attachment.blob.variant_records` chain AND
      #     `authorization&.raw&.[]("avatar_url")` (the OAuth fallback).
      #   - `:currency` → `pre_order.currency.icon_url`,
      #     `pre_order.amount_tag`
      #
      # `admin_user_field_preloads` is the canonical preload chain used by
      # every sibling admin index (`Admin::OrdersController`,
      # `Admin::PaymentsController`, `Admin::TransfersController`,
      # `Admin::BonusesController`, `Admin::ArticlesController`). Without
      # it, each row triggers ~3 extra SELECTs (authorization + avatar
      # attachment + blob/variant) — for the default pagy page of 50
      # pre-orders that's ~150 extra SELECTs per request.
      @pagy, @pre_orders = pagy(:countless, pre_orders.includes(:item, :currency, payer: admin_user_field_preloads))
    end

    def show
      @pre_order = PreOrder.find_by follow_id: params[:follow_id]
    end
  end
end
