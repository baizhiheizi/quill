# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :load_article, only: :index
  before_action :authenticate_user!, only: :create

  def index
    comments =
      if @article.present?
        @article.comments
      else
        Comment.none
      end

    @order_by = params[:order_by] || 'upvotes'
    comments =
      case @order_by
      when 'upvotes'
        comments.order(upvotes_count: :desc, downvotes_count: :asc, created_at: :desc)
      when 'asc'
        comments.order(created_at: :asc)
      else
        comments.order(created_at: :desc)
      end

    @pagy, @comments = pagy comments.without_deleted.includes(:author)
  end

  def create
    @comment = current_user.comments.create comment_params
  end

  def new
    if params[:quote_comment_id].present?
      @quote_comment = Comment.find_by id: params[:quote_comment_id]
      @commentable = @quote_comment&.commentable
    elsif params[:commentable_type] == 'Article'
      @commentable = Article.find_by id: params[:commentable_id]
    end
    return if @commentable.blank?
  end

  private

  def load_article
    @article = Article.only_published.find_by uuid: params[:article_uuid] if params[:article_uuid].present?
  end

  def comment_params
    params.require(:comment).permit(:commentable_id, :commentable_type, :content, :quote_comment_id)
  end
end
