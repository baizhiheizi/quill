# frozen_string_literal: true

module Admin
  class CommentsController < Admin::BaseController
    def index
      comments = Comment.all

      comments = comments.where(author_id: params[:author_id]) if params[:author_id].present?
      comments = comments.where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type]) if params[:commentable_id].present? && params[:commentable_type].present?

      @state = params[:state] || 'all'
      comments =
        case @state
        when 'deleted'
          comments.only_deleted
        when 'without_deleted'
          comments.without_deleted
        else
          comments
        end

      @order_by = params[:order_by] || 'created_at_desc'
      comments =
        case @order_by
        when 'created_at_desc'
          comments.order(created_at: :desc)
        when 'created_at_asc'
          comments.order(updated_at: :desc)
        when 'upvotes_count'
          comments.order(upvotes_count: :desc, created_at: :desc)
        when 'downvotes_count'
          comments.order(downvotes_count: :desc, created_at: :desc)
        end

      @query = params[:query].to_s.strip
      comments =
        comments.ransack(
          {
            content_i_cont_all: @query,
            id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @comments = pagy_countless comments
    end

    def show
      @tab = params[:tab] || 'orders'
      @comment = Article.find_by uuid: params[:uuid]
    end

    def delete
      @comment = Comment.find_by(id: params[:comment_id])
      return if @comment.blank?

      @comment.soft_delete! unless @comment.deleted?
    end

    def undelete
      @comment = Comment.find_by(id: params[:comment_id])
      return if @comment.blank?

      @comment.soft_undelete! if @comment.deleted?
    end
  end
end
