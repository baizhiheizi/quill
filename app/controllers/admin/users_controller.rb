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

      @pagy, @users = pagy(:countless, users)
      preload_user_aggregates(@users)
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

    private

    # Batched aggregate preloader for the admin user list.
    #
    # `Users::Statable#bought_articles_count`, `#payment_total_usd`, and
    # `#author_revenue_total_usd` are called from `app/views/admin/users/_user.html.erb`
    # once per user. The naive implementations each fire one SQL query
    # (count / sum / joined-sum), so a 24-user page costs ~72 queries just for
    # these three columns — and the `author_revenue_total_usd` variant joins
    # `currencies`, which is the slowest of the three.
    #
    # This helper replaces those 72 queries with **3 batched GROUP BY queries**
    # and primes the per-user memoization instance variables used by the model
    # methods (`||=` short-circuits when the ivar is already set, so the view
    # renders the precomputed values without touching the DB).
    #
    # The aggregation semantics are unchanged:
    #   - `bought_articles_count`   → count of `Order` rows where
    #     `order_type: :buy_article` for that `buyer_id`
    #     (matches `User#bought_articles`, which is `has_many :through` →
    #     `buy_orders` filtered by `order_type`).
    #   - `payment_total_usd`       → `SUM(orders.value_usd)` for that
    #     `buyer_id`. `value_usd` is snapshotted on the Order at create time,
    #     so the per-buyer sum is equivalent to summing all of the buyer's
    #     order rows (the previous method summed every Order, not just buy
    #     orders — preserved here for behaviour parity).
    #   - `author_revenue_total_usd` → `SUM(amount * currencies.price_usd)`
    #     over `transfers` with `transfer_type: :author_revenue`, grouped by
    #     `opponent_id` (the recipient's `mixin_uuid`).
    #
    # If `@users` is empty (no rows match the filter / search), the helper is
    # a no-op so it never adds queries on empty result sets.
    def preload_user_aggregates(users)
      return if users.blank?

      user_ids = users.map(&:id)
      mixin_uuids = users.map(&:mixin_uuid).compact

      bought_by_buyer_id = Order
        .where(order_type: :buy_article, buyer_id: user_ids)
        .group(:buyer_id)
        .count

      payment_by_buyer_id = Order
        .where(buyer_id: user_ids)
        .group(:buyer_id)
        .sum(:value_usd)

      author_revenue_by_opponent_id = Transfer
        .joins(:currency)
        .where(transfer_type: :author_revenue, opponent_id: mixin_uuids)
        .group(:opponent_id)
        .sum("amount * currencies.price_usd")

      users.each do |u|
        # Pre-populate the memoization ivars used by `Users::Statable`.
        # `||=` short-circuits, so subsequent `user.bought_articles_count`
        # calls in the view return these values without hitting the DB.
        u.instance_variable_set(
          :@bought_articles_count,
          bought_by_buyer_id[u.id] || 0
        )
        u.instance_variable_set(
          :@payment_total_usd,
          (payment_by_buyer_id[u.id] || 0).to_f
        )
        u.instance_variable_set(
          :@author_revenue_total_usd,
          (author_revenue_by_opponent_id[u.mixin_uuid] || 0).to_f
        )
      end
    end
  end
end
