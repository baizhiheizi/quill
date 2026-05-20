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
