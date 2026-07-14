# frozen_string_literal: true

module Admin
  class CommentsController < Admin::BaseController
    def index
      comments = Comment.all

      comments = comments.where(author_id: params[:author_id]) if params[:author_id].present?
      comments = comments.where(commentable_id: params[:commentable_id], commentable_type: params[:commentable_type]) if params[:commentable_id].present? && params[:commentable_type].present?

      @state = params[:state] || "all"
      comments =
        case @state
        when "deleted"
          comments.only_deleted
        when "without_deleted"
          comments.without_deleted
        else
          comments
        end

      @order_by = params[:order_by] || "created_at_desc"
      comments =
        case @order_by
        when "created_at_desc"
          comments.order(created_at: :desc)
        when "created_at_asc"
          comments.order(updated_at: :desc)
        when "upvotes_count"
          comments.order(upvotes_count: :desc, created_at: :desc)
        when "downvotes_count"
          comments.order(downvotes_count: :desc, created_at: :desc)
        end

      @query = params[:query].to_s.strip
      comments =
        comments.ransack(
          {
            content_i_cont_all: @query,
            id_eq: @query
          }.merge(m: "or")
        ).result

      # Eager-load associations consumed by the rendered partial
      # `app/views/admin/comments/_comment.html.erb`:
      #   - `author: admin_user_field_preloads` →
      #     `render "admin/users/field", user: comment.author, ...`
      #     → `shared/_avatar` with `thumb: true` → `user.avatar_image_thumb`
      #     walks the ActiveStorage `:avatar_attachment.blob.variant_records`
      #     chain AND `authorization&.raw&.[]("avatar_url")` (the OAuth
      #     fallback used when no avatar is attached).
      #     `admin_user_field_preloads` is the canonical preload chain used
      #     by every sibling admin index (`Admin::OrdersController`,
      #     `Admin::PaymentsController`, `Admin::TransfersController`,
      #     `Admin::BonusesController`, `Admin::ArticlesController`).
      #   - `:commentable` → `render "admin/articles/field", article: comment.commentable, ...`
      #     (`commentable` is polymorphic; Rails 7+ groups preloaded polymorphic
      #     rows by `item_type` so the partial only sees in-memory objects).
      #
      # Without the deep author chain each row triggers ~3 extra SELECTs
      # (authorization + avatar_attachment + blob/variant). For an admin
      # viewing a pagy page of 50 comments that's ~150 extra SELECTs per
      # request — same N+1 family PR #1895 closed for `Admin::UsersController#index`.
      @pagy, @comments = pagy(:countless, comments.includes(:commentable, author: admin_user_field_preloads))
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
