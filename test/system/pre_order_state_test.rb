# frozen_string_literal: true

require "application_system_test_case"

class PreOrderStateTest < ApplicationSystemTestCase
  driven_by :rack_test

  include CommerceHelpers
  include QuillBotStub

  test "paid pre_order is marked paid in the database" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      pre_order = MixinPreOrder.create!(
        item: article,
        payer: buyer,
        order_type: :buy_article,
        amount: article.price,
        asset_id: article.asset_id
      )
      pre_order.define_singleton_method(:broadcast_to_views) { }
      pre_order.pay!

      assert pre_order.paid?
    end
  end
end
