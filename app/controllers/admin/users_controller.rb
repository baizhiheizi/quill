# frozen_string_literal: true

module Admin
  class UsersController < Admin::BaseController
    def index
      users = User.all

      @filter = params[:filter] || 'all'
      users =
        case @filter
        when 'mixin'
          users.only_mixin_messenger
        when 'fennec'
          users.only_fennec
        when 'only_banned'
          users.only_banned
        when 'all'
          users
        end

      @order_by = params[:order_by] || 'created_at_desc'
      users =
        case @order_by
        when 'created_at_desc'
          users.order(created_at: :desc)
        when 'created_at_asc'
          users.order(created_at: :asc)
        when 'revenue_total'
          users.order_by_revenue_total
        when 'orders_total'
          users.order_by_orders_total
        when 'articles_count'
          users.order_by_articles_count
        when 'comments_count'
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
          }.merge(m: 'or')
        ).result

      @pagy, @users = pagy_countless users
    end

    def show
      @tab = params[:tab] || 'articles'
      @user = User.find_by uid: params[:uid]
    end
  end
end
