# frozen_string_literal: true

module Admin
  class UsersController < Admin::BaseController
    def index
      users = User.all

      @filter = params[:filter] || "all"
      users =
        case @filter
        when "mixin"
          users.only_mixin_messenger
        when "only_validated"
          users.only_validated
        when "only_blocked"
          users.only_blocked
        when "all"
          users
        end

      @order_by = params[:order_by] || "created_at_desc"
      users =
        case @order_by
        when "created_at_desc"
          users.order(created_at: :desc)
        when "created_at_asc"
          users.order(created_at: :asc)
        when "revenue_total"
          users.order_by_revenue_total
        when "orders_total"
          users.order_by_orders_total
        when "articles_count"
          users.order_by_articles_count
        when "comments_count"
          users.order_by_comments_count
        end

      @query = params[:query].to_s.strip
      users =
        users.ransack(
          {
            name_i_cont_any: @query,
            mixin_id_cont_all: @query,
            id_eq: @query,
            uid_cont_all: @query
          }.merge(m: "or")
        ).result

      # Eager-load the avatar chain (`shared/_avatar` → `user.avatar_image_thumb`
      # walks `User#avatar_attachment.blob.variant_records` plus the OAuth
      # `authorization.raw["avatar_url"]` fallback). Without this, each row
      # fires ~3 SELECTs (authorization + attachment + blob/variant); for the
      # default pagy page of 24 users that's ~72 extra SELECTs per request.
      # Same `User::AVATAR_PRELOADS` chain as `Admin::OrdersController`,
      # `Admin::ArticlesController`, `Admin::TransfersController`, and the
      # dashboard orders/articles preloads (consolidated in PR #1841/#1876).
      users = users.includes(*User::AVATAR_PRELOADS)
      @pagy, @users = pagy(:countless, users)

      # The `_user` partial reads `bought_articles_count`, `payment_total_usd`
      # and `author_revenue_total_usd` once per row. The bulk pass collapses
      # the resulting ~72 per-user queries into 3 batched GROUP BY queries —
      # see `Users::Statable.preload_aggregates`, which owns that memoization.
      User.preload_aggregates(@users)
    end

    def show
      @tab = params[:tab] || "articles"
      @user = User.find_by uid: params[:uid]
    end

    def block
      @user = User.find_by uid: params[:user_uid]
      return if @user.blank?

      @user.block! unless @user.blocked?
    end

    def unblock
      @user = User.find_by uid: params[:user_uid]
      @user.unblock! if @user&.blocked?
    end

    def validate
      @user = User.find_by uid: params[:user_uid]
      return if @user.blank?

      @user.validate! unless @user.validated?
    end

    def unvalidate
      @user = User.find_by uid: params[:user_uid]
      @user.unvalidate! if @user&.validated?
    end
  end
end
