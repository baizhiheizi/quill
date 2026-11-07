# frozen_string_literal: true

class MixpayPreOrdersController < ApplicationController
  before_action :authenticate_user!

  def show
    # item_type/item_id come from the query string, and a stale or crafted
    # link can name an item that no longer exists (or anything at all) — the
    # failed-save branch below would raise on the unresolved `item`
    # association. Resolve it up front and bounce instead.
    item = params[:item_type].presence_in(%w[Article Collection])&.constantize&.find_by(id: params[:item_id])

    return redirect_to root_path if item.blank?

    @pre_order = current_user.pre_orders.new pre_order_params

    if @pre_order.save
      PostHog.capture(
        distinct_id: current_user.posthog_distinct_id,
        event: "payment_initiated",
        properties: {
          item_type: @pre_order.item_type,
          order_type: @pre_order.order_type,
          asset_id: @pre_order.asset_id
        }
      )
      redirect_to @pre_order.pay_url, allow_other_host: true
    else
      redirect_to user_article_path(@pre_order.item.author, @pre_order.item) if @pre_order.item.is_a?(Article)
      redirect_to collection_path(@pre_order.item.uuid) if @pre_order.item.is_a?(Collection)
    end
  end

  private

  def pre_order_params
    params
      .permit(:item_id, :item_type, :type, :order_type, :asset_id, :amount)
      .merge(type: "MixpayPreOrder")
  end
end
