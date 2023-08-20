# frozen_string_literal: true

class PreOrdersController < ApplicationController
  before_action :authenticate_user!

  def show
    @pre_order = current_user.pre_orders.find_by follow_id: params[:follow_id]

    respond_to do |format|
      format.html do
        if @pre_order.blank?
          redirect_to root_path
        elsif @pre_order.item.authorized?(current_user)
          redirect_to user_article_path(@pre_order.item.author, @pre_order.item) if @pre_order.item.is_a?(Article)
          redirect_to collection_path(@pre_order.item.uuid) if @pre_order.item.is_a?(Collection)
        else
          render :show
        end
      end

      format.turbo_stream do
        render :show
      end
    end
  end

  def new
    article = Article.published.find_by uuid: params[:article_uuid]

    return if article.blank?
    return if params[:order_type] == 'buy_article' && article.authorized?(current_user)
    return if params[:order_type] == 'reward_article' && !article.authorized?(current_user)

    @pre_order = current_user.pre_orders.new item: article, order_type: params[:order_type]
  end

  def create
    @pre_order = current_user.pre_orders.new pre_order_params

    redirect_to @pre_order.pay_url, allow_other_host: true if @pre_order.save && @pre_order.is_a?(MixpayPreOrder)
  end

  def state
    @pre_order = current_user.pre_orders.find_by follow_id: params[:pre_order_follow_id]
    redirect_url =
      if @pre_order.blank?
        root_path
      elsif @pre_order.paid?
        case @pre_order.item
        when Article
          user_article_path @pre_order.item.author, @pre_order.item
        when Collection
          collection_path @pre_order.item.uuid
        end
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
    true if @pre_order.order_type.reward_article?
  end
end
