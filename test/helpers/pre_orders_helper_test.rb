# frozen_string_literal: true

require "test_helper"

# Covers `PreOrdersHelper#pre_order_form_price`, the price displayed in
# the new-pre-order form. The helper switches on `pre_order.order_type`:
# reward pre-orders always quote the currency's `minimal_reward_amount`
# (so the reader cannot reward below the network minimum), while buy
# pre-orders quote the article's own `price` column. Any other order
# type (notably `buy_collection`) is not handled by the helper and must
# fall through to `nil` so the caller renders nothing.
class PreOrdersHelperTest < ActionView::TestCase
  setup do
    @article = articles(:published_paid)
    @currency = currencies(:btc)
  end

  test "buy_article pre_orders render the article's configured price" do
    pre_order = build_pre_order(order_type: "buy_article")

    assert_equal @article.price, pre_order_form_price(pre_order)
  end

  test "reward_article pre_orders render the currency's minimal reward amount" do
    pre_order = build_pre_order(order_type: "reward_article")

    # The helper must read `article.currency.minimal_reward_amount`
    # rather than `article.price` for reward pre-orders; the article's
    # own price is irrelevant for rewards, only the network minimum is.
    assert_equal @article.currency.minimal_reward_amount,
                 pre_order_form_price(pre_order)
  end

  test "unknown order_type falls through to nil" do
    pre_order = build_pre_order(order_type: "buy_collection")

    assert_nil pre_order_form_price(pre_order)
  end

  private

  def build_pre_order(order_type:)
    stub = PreOrder.new(order_type: order_type)
    stub.item = @article
    stub.currency = @currency
    stub
  end
end
