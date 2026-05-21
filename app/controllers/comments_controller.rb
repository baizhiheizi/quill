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

    @order_by = params[:order_by] || "upvotes"
    comments =
      case @order_by
      when "upvotes"
        comments.order(upvotes_count: :desc, downvotes_count: :asc, created_at: :desc)
      when "asc"
        comments.order(created_at: :asc)
      else
        comments.order(created_at: :desc)
      end

    @pagy, @comments = pagy comments.without_deleted.includes(:author)
  end

  def new
    if params[:quote_comment_id].present?
      @quote_comment = Comment.find_by id: params[:quote_comment_id]
      @commentable = @quote_comment&.commentable
    elsif params[:commentable_type] == "Article"
      @commentable = Article.find_by id: params[:commentable_id]
    end
    nil if @commentable.blank?
  end

  def create
    commentable = find_commentable
    return head :forbidden if commentable.blank?

    @comment = current_user.comments.create(
      comment_params.except(:commentable_id, :commentable_type).merge(commentable:)
    )
  end

  private

  def find_commentable
    if params.dig(:comment, :quote_comment_id).present?
      quote_comment = Comment.find_by(id: params.dig(:comment, :quote_comment_id))
      commentable = quote_comment&.commentable
    elsif params.dig(:comment, :commentable_type) == "Article"
      commentable = Article.without_drafted.find_by(id: params.dig(:comment, :commentable_id))
    end

    return if commentable.blank?
    return unless commentable.is_a?(Article)
    return unless commentable.published? || commentable.authorized?(current_user)

    commentable
  end

  def load_article
    article = Article.without_drafted.find_by uuid: params[:article_uuid]
    @article = article if article&.published? || article&.authorized?(current_user)
  end

  def comment_params
    params.require(:comment).permit(:commentable_id, :commentable_type, :content, :quote_comment_id)
  end
end
