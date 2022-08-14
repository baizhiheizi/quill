# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type = params[:type]

    case type
    when 'publish_article'
      @article = current_user.articles.find_by uuid: params[:uuid]
      return if @article.blank?
    when 'comment_form'
      if params[:quote_comment_id].present?
        @quote_comment = Comment.find_by id: params[:quote_comment_id]
        @commentable = @quote_comment&.commentable
      elsif params[:commentable_type] == 'Article'
        @commentable = Article.find_by id: params[:commentable_id]
      end
      return if @commentable.blank?
    when 'pre_order'
      @pre_order = current_user.pre_orders.find_by follow_id: params[:follow_id]
      return if @pre_order.blank?
    end

    render type
  end
end
