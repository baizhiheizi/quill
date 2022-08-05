# frozen_string_literal: true

class MixpayPreOrdersController < ApplicationController
  before_action :authenticate_user!

  def show
    @pre_order = current_user.pre_orders.new pre_order_params

    redirect_to @pre_order.pay_url, allow_other_host: true if @pre_order.save
  end

  private

  def pre_order_params
    params
      .permit(:item_id, :item_type, :type, :order_type, :asset_id, :amount)
      .merge(type: 'MixpayPreOrder')
  end
end
