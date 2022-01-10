# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :load_article, only: :index
  before_action :authenticate_user!, only: :create

  def index
    comments =
      if @article.present?
        @article.comments.without_deleted
      else
        Comment.without_deleted
      end

    @order_by = params[:order_by] || 'upvotes'
    comments =
      case @order_by
      when 'upvotes'
        comments.order(upvotes_count: :desc, downvotes_count: :asc)
      when 'asc'
        comments.order(created_at: :asc)
      else
        comments.order(created_at: :desc)
      end

    @pagy, @comments = pagy comments.includes(:author)
  end

  def create
    @comment = current_user.comments.create! comment_params
  end

  private

  def load_article
    @article = Article.only_published.find_by uuid: params[:article_uuid]
  end

  def comment_params
    params.require(:comment).permit(:commentable_id, :commentable_type, :content)
  end
end
