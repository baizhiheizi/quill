# frozen_string_literal: true

require "test_helper"

# Covers `PreOrdersHelper#pre_order_form_price`, the price displayed in
# the new-pre-order form. The helper switches on `pre_order.order_type`:
# reward pre-orders always quote the currency's `minimal_reward_amount`
# (so the reader cannot reward below the network minimum), while every
# other order type quotes the item's own `price` column. The helper used
# to fall through to `nil` for anything else, which made the form call
# `sprintf('%.8f', nil)` and raise.
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

  test "buy_collection pre_orders render the item's configured price" do
    pre_order = build_pre_order(order_type: "buy_collection")

    assert_equal @article.price, pre_order_form_price(pre_order)
  end

  test "an unsupported order type falls back to the item's price instead of nil" do
    pre_order = build_pre_order(order_type: "not_an_order_type")

    assert_equal @article.price, pre_order_form_price(pre_order)
  end

  private

  def build_pre_order(order_type:)
    stub = PreOrder.new(order_type: order_type)
    stub.item = @article
    stub.currency = @currency
    stub
  end
end
