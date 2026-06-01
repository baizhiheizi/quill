# frozen_string_literal: true

require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @payer = users(:reader_one)
  end

  test "memo_correct? validates BUY memos" do
    memo = build_payment_memo(type: "BUY", article: @article)
    payment = Payment.new(memo: memo)

    assert payment.memo_correct?
  end

  test "decoded_memo parses base64 payload" do
    memo = build_payment_memo(type: "REWARD", article: @article)
    payment = Payment.new(memo: memo)

    assert_equal "REWARD", payment.decoded_memo["t"]
    assert_equal @article.uuid, payment.decoded_memo["a"]
  end

  test "BUY payment creates buy_article order" do
    with_quill_bot_stub do
      payment = create_payment!(payer: @payer, article: @article, order_type: "BUY", amount: @article.price)

      assert payment.completed?
      assert_equal "buy_article", payment.order.order_type
      assert_equal @payer, payment.order.buyer
    end
  end

  test "REWARD payment creates reward_article order" do
    with_quill_bot_stub do
      payment = create_payment!(payer: @payer, article: @article, order_type: "REWARD", amount: 0.5)

      assert payment.completed?
      assert_equal "reward_article", payment.order.order_type
    end
  end

  test "REVENUE payment completes without order" do
    with_quill_bot_stub do
      payment = create_payment!(payer: @payer, article: @article, order_type: "REVENUE", amount: 0.01)

      assert payment.completed?
      assert_nil payment.order
    end
  end

  test "memo_correct? rejects memos without article or collection id" do
    payload = Base64.encode64({ "t" => "BUY" }.to_json)
    payment = Payment.new(memo: payload)

    refute payment.memo_correct?
  end

  test "memo_correct? rejects unknown transaction types" do
    memo = build_payment_memo(type: "SWAP", article: @article)
    payment = Payment.new(memo: memo)

    refute payment.memo_correct?
  end

  test "CITE payment creates cite_article order with citer" do
    citer = articles(:high_revenue)

    with_quill_bot_stub do
      memo = build_payment_memo(type: "CITE", article: @article, citer: citer)
      payment = create_payment_from_memo!(
        memo: memo,
        payer: citer.author,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert payment.completed?
      assert_equal "cite_article", payment.order.order_type
      assert_equal citer, payment.order.citer
      assert_equal citer.author, payment.payer
    end
  end

  test "collection BUY payment creates buy_collection order" do
    collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Payment Test Collection",
      symbol: "PTC",
      description: "Collection for payment tests",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )

    with_quill_bot_stub do
      payment = create_payment!(
        payer: @payer,
        collection: collection,
        order_type: "BUY",
        amount: collection.price
      )

      assert payment.completed?
      assert_equal "buy_collection", payment.order.order_type
      assert_equal collection, payment.order.item
    end
  end

  test "blocked buyer payment triggers refund instead of order" do
    @article.author.block_user(@payer)

    with_quill_bot_stub do
      payment = create_payment!(payer: @payer, article: @article, order_type: "BUY", amount: @article.price)

      assert_nil payment.order
      assert payment.refund_transfer.present?
    end
  end

  test "invalid memo does not create order" do
    with_quill_bot_stub do
      payment = nil
      stub_notifications! do
        payment = Payment.create!(
          amount: @article.price,
          raw: {
            "amount" => @article.price.to_s,
            "asset_id" => @article.asset_id,
            "memo" => "not-valid-base64-memo",
            "opponent_id" => @payer.mixin_uuid,
            "snapshot_id" => SecureRandom.uuid,
            "trace_id" => SecureRandom.uuid
          },
          asset_id: @article.asset_id,
          snapshot_id: SecureRandom.uuid,
          trace_id: SecureRandom.uuid,
          payer: @payer
        )
      end

      assert_nil payment.order
    end
  end
end
