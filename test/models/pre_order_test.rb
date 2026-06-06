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
  test "decoded_memo encodes BUY for buy_article" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: articles(:published_paid),
        payer: users(:reader_one),
        order_type: :buy_article,
        amount: articles(:published_paid).price,
        asset_id: articles(:published_paid).asset_id
      )

      assert_equal "BUY", pre_order.decoded_memo["t"]
      assert_equal articles(:published_paid).uuid, pre_order.decoded_memo["a"]
    end
  end

  test "rejects author as payer" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.new(
        item: articles(:published_paid),
        payer: users(:author),
        order_type: :buy_article,
        amount: articles(:published_paid).price,
        asset_id: articles(:published_paid).asset_id
      )

      assert_not pre_order.valid?
      assert_includes pre_order.errors[:payer], "cannot be author"
    end
  end

  test "pay transitions drafted to paid" do
    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: articles(:published_paid),
        payer: users(:reader_one),
        order_type: :buy_article,
        amount: articles(:published_paid).price,
        asset_id: articles(:published_paid).asset_id
      )

      pre_order.define_singleton_method(:broadcast_to_views) { }
      pre_order.pay!

      assert pre_order.paid?
    end
  end
end
