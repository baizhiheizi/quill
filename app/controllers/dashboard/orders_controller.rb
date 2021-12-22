# frozen_string_literal: true

class Dashboard::OrdersController < Dashboard::BaseController
  before_action :load_article

  def index
    @tab = params[:tab] || 'payments'

    load_article_orders if @article.present?
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:article_uuid]
  end

  def load_article_orders
    @order_type = params[:order_type]
    orders =
      case @order_type
      when 'buy_article'
        @article.orders.where(order_type: :buy_article)
      when 'reward_article'
        @article.orders.where(order_type: :reward_article)
      when 'cite_article'
        @article.orders.where(order_type: :cite_article)
      else
        @article.orders
      end

    @pagy, @orders = pagy orders.includes(:item, :citer, :buyer).order(created_at: :desc)
  end
end
