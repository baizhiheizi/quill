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

class PreOrderTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @author = users(:author)
    @reader = users(:reader_one)
  end

  # === Validations ===

  test "rejects author as payer" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.new(
        item: @article,
        payer: @author,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_not pre_order.valid?
      assert_includes pre_order.errors[:payer], "cannot be author"
    end
  end

  test "rejects non-positive amount" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.new(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: 0,
        asset_id: @article.asset_id
      )

      assert_not pre_order.valid?
      assert pre_order.errors[:amount].any?
    end
  end

  test "requires trace_id" do
    with_quill_bot_stub do
      # Skip the before_validation callback that auto-fills trace_id.
      pre_order = MixinPreOrder.new(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id,
        trace_id: nil
      )
      pre_order.define_singleton_method(:setup_attributes) { }

      assert_not pre_order.valid?
      assert pre_order.errors[:trace_id].any?
    end
  end

  test "requires memo" do
    with_quill_bot_stub do
      # Skip the before_validation callback that auto-fills memo.
      pre_order = MixinPreOrder.new(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id,
        memo: nil
      )
      pre_order.define_singleton_method(:setup_attributes) { }

      assert_not pre_order.valid?
      assert pre_order.errors[:memo].any?
    end
  end

  test "auto-assigns follow_id on create" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert pre_order.follow_id.present?
      assert_match(/\A[0-9a-f-]{36}\z/, pre_order.follow_id)
    end
  end

  test "auto-assigns asset_id from item when blank" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price
      )

      assert_equal @article.asset_id, pre_order.asset_id
    end
  end

  test "auto-assigns payee_id to QuillBot client_id" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_equal QuillBot.api.client_id, pre_order.payee_id
    end
  end

  # === Memo encoding (decoded_memo) ===

  test "decoded_memo encodes BUY for buy_article" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_equal "BUY", pre_order.decoded_memo["t"]
      assert_equal @article.uuid, pre_order.decoded_memo["a"]
      assert_equal pre_order.follow_id, pre_order.decoded_memo["f"]
    end
  end

  test "decoded_memo encodes REWARD for reward_article" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :reward_article,
        amount: 0.5,
        asset_id: @article.asset_id
      )

      assert_equal "REWARD", pre_order.decoded_memo["t"]
      assert_equal @article.uuid, pre_order.decoded_memo["a"]
      assert_equal pre_order.follow_id, pre_order.decoded_memo["f"]
    end
  end

  test "decoded_memo encodes BUY for buy_collection with collection uuid" do
    with_quill_bot_stub do
      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "PreOrder Test Collection",
        symbol: "POTC",
        description: "For pre_order buy_collection memo test",
        author: @author,
        asset_id: @article.asset_id,
        price: 0.001,
        revenue_ratio: 0.1,
        state: "listed"
      )

      pre_order = MixinPreOrder.create!(
        item: collection,
        payer: @reader,
        order_type: :buy_collection,
        amount: collection.price,
        asset_id: collection.asset_id
      )

      assert_equal "BUY", pre_order.decoded_memo["t"]
      assert_equal collection.uuid, pre_order.decoded_memo["l"]
      assert_equal pre_order.follow_id, pre_order.decoded_memo["f"]
    end
  end

  test "decoded_memo memo uses urlsafe base64 (no padding)" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_not_includes pre_order.memo, "="
      # urlsafe alphabet uses '-' and '_' instead of '+' and '/'.
      assert_not_includes pre_order.memo, "+"
      assert_not_includes pre_order.memo, "/"
    end
  end

  # === State machine (AASM) ===

  test "initial state is drafted" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert pre_order.drafted?
    end
  end

  test "pay transitions drafted to paid" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      pre_order.define_singleton_method(:broadcast_to_views) { }
      pre_order.pay!

      assert pre_order.paid?
    end
  end

  test "expire transitions drafted to expired" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      pre_order.expire!

      assert pre_order.expired?
    end
  end

  test "expire fails when pre_order is already paid" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      pre_order.define_singleton_method(:broadcast_to_views) { }
      pre_order.pay!

      assert_raises(AASM::InvalidTransition) do
        pre_order.expire!
      end
    end
  end

  test "pay fails when pre_order is expired" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      pre_order.expire!

      assert_raises(AASM::InvalidTransition) do
        pre_order.define_singleton_method(:broadcast_to_views) { }
        pre_order.pay!
      end
    end
  end

  test "pay triggers broadcast_to_views as after_commit callback" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      called = false
      pre_order.define_singleton_method(:broadcast_to_views) { called = true }
      pre_order.pay!

      assert called, "Expected broadcast_to_views to run after pay! commit"
    end
  end

  # === Display helpers ===

  test "to_param returns follow_id" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      assert_equal pre_order.follow_id, pre_order.to_param
    end
  end

  test "amount_tag formats amount with currency symbol and strips trailing zeros" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        order_type: :buy_article,
        amount: 0.00010000,
        asset_id: @article.asset_id
      )

      # Trailing zeros after the decimal are stripped, but a single trailing
      # zero is kept so the integer part is unambiguous (0.00010 -> "0.00010").
      assert_match(/BTC\z/, pre_order.amount_tag)
      assert_match(/\A0\.0001(0)?\sBTC\z/, pre_order.amount_tag)
    end
  end
end
