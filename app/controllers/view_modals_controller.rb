# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type =
      if current_user.blank? && !params[:type].in?(%w[login walletconnect])
        'login'
      else
        params[:type]
      end

    case type
    when 'publish_article'
      @article = current_user.articles.find_by uuid: params[:uuid]
      return if @article.blank?
    when 'share_article'
      @article = Article.published.find_by uuid: params[:uuid]
    when 'comment_form'
      if params[:quote_comment_id].present?
        @quote_comment = Comment.find_by id: params[:quote_comment_id]
        @commentable = @quote_comment&.commentable
      elsif params[:commentable_type] == 'Article'
        @commentable = Article.find_by id: params[:commentable_id]
      end
      return if @commentable.blank?
    when 'pre_order_form'
      @article = Article.published.find_by uuid: params[:uuid]

      return if @article.blank?
      return if params[:order_type] == 'buy_article' && @article.authorized?(current_user)
      return if params[:order_type] == 'reward_article' && !@article.authorized?(current_user)
    when 'pre_order'
      @pre_order = current_user.pre_orders.find_by follow_id: params[:follow_id]
      return if @pre_order.blank?
    end

    render type
  end
end
