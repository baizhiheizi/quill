# frozen_string_literal: true

class MixpayPreOrdersController < ApplicationController
  before_action :authenticate_user!

  def show
    @pre_order = current_user.pre_orders.new pre_order_params

    if @pre_order.save
      redirect_to @pre_order.pay_url, allow_other_host: true
    else
      redirect_to user_article_path(@pre_order.item.author, @pre_order.item)
    end
  end

  private

  def pre_order_params
    params
      .permit(:item_id, :item_type, :type, :order_type, :asset_id, :amount)
      .merge(type: 'MixpayPreOrder')
  end
end
