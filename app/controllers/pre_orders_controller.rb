# frozen_string_literal: true

class PreOrdersController < ApplicationController
  before_action :authenticate_user!

  def create
    @pre_order = current_user.pre_orders.new pre_order_params

    redirect_to @pre_order.pay_url, allow_other_host: true if @pre_order.save && @pre_order.is_a?(MixpayPreOrder)
  end

  def show
    @pre_order = current_user.pre_orders.find_by follow_id: params[:follow_id]

    respond_to do |format|
      format.html do
        if @pre_order.blank?
          redirect_to root_path
        elsif @pre_order.item.authorized?(current_user)
          redirect_to user_article_path(@pre_order.item.author, @pre_order.item)
        end

        render :show
      end

      format.turbo_stream do
        render :show
      end
    end
  end

  def new
  end

  def state
    @pre_order = current_user.pre_orders.find_by follow_id: params[:pre_order_follow_id]
    redirect_url =
      if @pre_order.blank?
        root_path
      elsif @pre_order.item.authorized?(current_user)
        user_article_path @pre_order.item.author, @pre_order.item
      end

    render json: {
      redirect_url: redirect_url
    }
  end

  private

  def pre_order_params
    params.require(:pre_order).permit(:item_id, :item_type, :type, :order_type, :asset_id, :amount)
  end

  def should_redirect?
    return true if @pre_order.order_type.reward_article?
  end
end
