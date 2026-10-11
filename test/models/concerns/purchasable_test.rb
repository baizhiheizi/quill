# frozen_string_literal: true

require "test_helper"

# Covers the shared `Purchasable` concern included by `Article` and
# `Collection`. `PreOrder#setup_attributes` derives its trace from
# `item.payment_trace_id` and `MixpayPreOrder` gates on
# `item.mixpay_supported?`, so both item types must answer identically.
class PurchasableTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @reader = users(:reader_one)
    @collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Purchasable Test Collection",
      symbol: "PT",
      description: "Shared purchase interface tests",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end

  test "payment_trace_id returns nil for a blank user on any item" do
    assert_nil articles(:published_paid).payment_trace_id(nil)
    assert_nil @collection.payment_trace_id(nil)
  end

  test "payment_trace_id is stable per item+user while no conflicting payment exists" do
    with_quill_bot_stub do
      article = articles(:published_paid)

      assert_equal article.payment_trace_id(@reader), article.payment_trace_id(@reader)
      assert_equal @collection.payment_trace_id(@reader), @collection.payment_trace_id(@reader)
      assert_not_equal article.payment_trace_id(@reader), @collection.payment_trace_id(@reader)
    end
  end

  test "mixpay_supported? is true when the asset is a settlement asset" do
    with_swapped_mixpay_api(settlement_assets: [ Currency::BTC_ASSET_ID ]) do
      assert @collection.mixpay_supported?
    end
  end

  test "mixpay_supported? is false when the asset is not a settlement asset" do
    with_swapped_mixpay_api(settlement_assets: []) do
      assert_not @collection.mixpay_supported?
      assert_not articles(:published_paid).mixpay_supported?
    end
  end

  test "mixpay_supported? swallows mixpay api failures" do
    with_swapped_mixpay_api(error: Mixpay::Errors::HttpError.new("connection failed")) do
      assert_not @collection.mixpay_supported?
      assert_not articles(:published_paid).mixpay_supported?
    end
  end

  test "article mixpay_supported? short-circuits free articles before consulting mixpay" do
    with_swapped_mixpay_api(settlement_assets: []) do
      assert articles(:published_free).mixpay_supported?
      assert_not articles(:published_paid).mixpay_supported?
    end
  end

  private

  # Swaps the Mixpay API singleton the same way `pre_order_test.rb` does,
  # restoring the original afterwards.
  def with_swapped_mixpay_api(settlement_assets: [], error: nil)
    api = Object.new
    api.define_singleton_method(:settlement_asset_ids) { error ? raise(error) : settlement_assets }

    original_api = Mixpay.instance_variable_get(:@api)
    Mixpay.instance_variable_set(:@api, api)
    yield
  ensure
    Mixpay.instance_variable_set(:@api, original_api)
  end
end
