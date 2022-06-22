# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type =
      if current_user.blank?
        'login'
      else
        params[:type]
      end

    case type
    when 'publish_article'
      @article = current_user.articles.find_by uuid: params[:uuid]
      return if @article.blank?
    when 'buy_article'
      @article = Article.published.find_by uuid: params[:uuid]
      return if @article.blank? || @article.authorized?(current_user)
    when 'reward_article'
      @article = Article.published.find_by uuid: params[:uuid]
      return unless @article&.authorized?(current_user)
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
    end

    render params[:type]
  end
end
