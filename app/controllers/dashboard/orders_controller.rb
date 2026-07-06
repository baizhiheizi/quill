# frozen_string_literal: true

class Dashboard::OrdersController < Dashboard::BaseController
  before_action :load_article

  def index
    @tab = params[:tab] || "payments"

    load_article_orders if @article.present?
  end

  private

  def load_article
    @article = current_user.articles.find_by uuid: params[:article_uuid]
  end

  def load_article_orders
    @order_type = params[:order_type]
    orders =
      case @order_type
      when "buy_article"
        @article.orders.where(order_type: :buy_article)
      when "reward_article"
        @article.orders.where(order_type: :reward_article)
      when "cite_article"
        @article.orders.where(order_type: :cite_article)
      else
        @article.orders
      end

    # Eager-load associations consumed by the rendered partial
    # `app/views/dashboard/orders/_article_order.html.erb`:
    #   - `:item`           → `order.item` is not surfaced in the partial but
    #     `:counter_cache` writes need the polymorphic target loaded; kept for
    #     parity with `Admin::OrdersController`.
    #   - `citer: :author`  → `order.citer.title` + `order.citer.author` are
    #     read on the `cite_article` branch (polymorphic Article citer). Rails
    #     7+ groups the polymorphic preload by `citer_type` and fires a
    #     follow-up SELECT for `:author` only when the citer is an Article,
    #     so the chain is safe for orders with no citer (the common case).
    #   - `:currency`       → `order.currency.symbol` in the price cell.
    #   - `buyer: user_field_preloads` → `shared/avatar` partial reads
    #     `user.avatar_image_thumb`, which loads `:authorization` (for the
    #     raw `avatar_url` fallback) and the ActiveStorage
    #     `avatar_attachment: blob: variant_records` chain (for `variant(:thumb)
    #     .processed.key`). Without these preloads each row triggers
    #     ~3 SELECTs (authorization + attachment + blob/variant).
    #
    # Before this include: 1 (orders) + 1N (item) + 1N (buyer) +
    #                      1N (authorization) + 1N (avatar_attachment) +
    #                      1N (blob) + N (citer author for cite rows)
    #                      ≈ 3N-5N SELECTs on a pagy page of 50.
    # After this include: 1 (orders) + 1-2 (polymorphic item) +
    #                     1 (buyers) + 1 (authorizations) +
    #                     1 (avatar_attachments) + 1 (blobs/variants) +
    #                     1 (citer authors when cite_article rows present)
    #                     ≈ 6-8 SELECTs total.
    @pagy, @orders = pagy orders.includes(:item, :currency, citer: :author, buyer: user_field_preloads).order(created_at: :desc)
  end
end
