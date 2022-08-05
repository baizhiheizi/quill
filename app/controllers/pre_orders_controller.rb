# frozen_string_literal: true

class PreOrdersController < ApplicationController
  before_action :authenticate_user!

  def create
    @pre_order = current_user.pre_orders.new pre_order_params

    redirect_to @pre_order.pay_url, allow_other_host: true if @pre_order.save && @pre_order.is_a?(MixpayPreOrder)
  end

  def show
    @pre_order = current_user.pre_orders.find params[:id]
    redirect_to user_artilce_path(@pre_order.item.author, @pre_order.item) if @pre_order.paid?
  end

  def new
  end

  private

  def pre_order_params
    params.require(:pre_order).permit(:item_id, :item_type, :type, :order_type, :asset_id, :amount)
  end
end
