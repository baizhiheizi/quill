# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_orders
# Database name: primary
#
#  id         :bigint           not null, primary key
#  amount     :decimal(, )
#  item_type  :string
#  memo       :string
#  order_type :string
#  state      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  follow_id  :uuid
#  item_id    :bigint
#  payee_id   :uuid
#  payer_id   :uuid
#  trace_id   :uuid
#
# Indexes
#
#  index_pre_orders_on_item      (item_type,item_id)
#  index_pre_orders_on_payee_id  (payee_id)
#  index_pre_orders_on_payer_id  (payer_id)
#
require "test_helper"

class MixpayPreOrderTest < ActiveSupport::TestCase
  include QuillBotStub

  setup do
    @article = articles(:published_paid)
    @author = users(:author)
    @reader = users(:reader_one)

    @original_mixpay_api = Mixpay.instance_variable_get(:@api)
    @mixpay_api = Object.new
    # Default: BTC is settlement-supported, and a quote asset that allows the
    # paid article's amount range (0.0001 BTC, well within min=0 / max=1).
    @mixpay_api.define_singleton_method(:settlement_asset_ids) do
      [ Currency::BTC_ASSET_ID ]
    end
    @mixpay_api.define_singleton_method(:quote_assets_cached) do
      [ { "assetId" => Currency::BTC_ASSET_ID, "minQuoteAmount" => "0", "maxQuoteAmount" => "1" } ]
    end
    Mixpay.instance_variable_set(:@api, @mixpay_api)
  end

  teardown do
    Mixpay.instance_variable_set(:@api, @original_mixpay_api)
  end

  # === STI ===

  test "is a PreOrder subclass with type=MixpayPreOrder" do
    with_quill_bot_stub do
      pre_order = MixpayPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_kind_of PreOrder, pre_order
      assert_equal "MixpayPreOrder", pre_order.type
    end
  end

  # === Validations ===

  test "rejects item whose asset_id is not in Mixpay settlement_asset_ids" do
    with_quill_bot_stub do
      # Article is paid (so mixpay_supported? requires settlement_asset_ids
      # membership). Stub a Mixpay API whose settlement set excludes BTC.
      Mixpay.instance_variable_set(:@api, Object.new.tap { |api|
        api.define_singleton_method(:settlement_asset_ids) { [ "other-asset-id" ] }
        api.define_singleton_method(:quote_assets_cached) { [] }
      })

      pre_order = MixpayPreOrder.new(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_not pre_order.valid?
      assert_includes pre_order.errors[:item], "not supported"
    end
  end

  test "accepts a mixpay-supported item" do
    with_quill_bot_stub do
      pre_order = MixpayPreOrder.new(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert pre_order.valid?, pre_order.errors.full_messages.to_s
    end
  end

  test "rejects a collection whose asset_id is not in Mixpay settlement_asset_ids" do
    with_quill_bot_stub do
      Mixpay.instance_variable_set(:@api, Object.new.tap { |api|
        api.define_singleton_method(:settlement_asset_ids) { [ "other-asset-id" ] }
        api.define_singleton_method(:quote_assets_cached) { [] }
      })

      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "MixpayPreOrder Test Collection",
        symbol: "MPTC",
        description: "For mixpay_pre_order validation test",
        author: @author,
        asset_id: Currency::BTC_ASSET_ID,
        price: 0.001,
        revenue_ratio: 0.1,
        state: "listed"
      )

      pre_order = MixpayPreOrder.new(
        item: collection,
        payer: @reader,
        order_type: :buy_collection,
        amount: collection.price,
        asset_id: collection.asset_id
      )

      assert_not pre_order.valid?
      assert_includes pre_order.errors[:item], "not supported"
    end
  end

  # === pay_url ===

  test "pay_url is an https mixpay.me/pay URL with all required query params" do
    with_quill_bot_stub do
      pre_order = MixpayPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      uri = URI.parse(pre_order.pay_url)

      assert_equal "https", uri.scheme
      assert_equal "mixpay.me", uri.host
      assert_equal "/pay", uri.path
    end
  end

  test "pay_url exposes payee, settlement/quote asset, amount, trace, memo, and returnTo" do
    with_quill_bot_stub do
      pre_order = MixpayPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      params = Addressable::URI.parse(pre_order.pay_url).query_values(Array)

      assert_equal [ [ "payeeId", QuillBotStub::FAKE_CLIENT_ID ] ], params.select { |k, _| k == "payeeId" }
      assert_equal [ [ "settlementAssetId", pre_order.asset_id ] ], params.select { |k, _| k == "settlementAssetId" }
      assert_equal [ [ "quoteAssetId", pre_order.asset_id ] ], params.select { |k, _| k == "quoteAssetId" }
      assert_equal [ [ "quoteAmount", pre_order.amount.to_s ] ], params.select { |k, _| k == "quoteAmount" }
      assert_equal [ [ "traceId", pre_order.trace_id ] ], params.select { |k, _| k == "traceId" }
      assert_equal [ [ "settlementMemo", pre_order.memo ] ], params.select { |k, _| k == "settlementMemo" }
      assert_equal [ [ "returnTo", Rails.application.routes.url_helpers.pre_order_url(pre_order.follow_id) ] ], params.select { |k, _| k == "returnTo" }
    end
  end

  test "pay_url returnTo points to pre_order_url scoped to follow_id" do
    with_quill_bot_stub do
      pre_order = MixpayPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      params = Hash[*Addressable::URI.parse(pre_order.pay_url).query_values(Array).flatten]
      expected_return_to = Rails.application.routes.url_helpers.pre_order_url(pre_order.follow_id)

      assert_equal expected_return_to, params["returnTo"]
      assert_includes expected_return_to, pre_order.follow_id
      assert_includes expected_return_to, "/pre_orders/"
    end
  end
end
