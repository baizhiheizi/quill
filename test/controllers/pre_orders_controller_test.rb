# frozen_string_literal: true

require "test_helper"

class PreOrdersControllerTest < IntegrationTestCase
  test "new buy is blocked when already authorized" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end
    sign_in(buyer)

    get new_pre_order_path(article_uuid: article.uuid, order_type: "buy_article")

    assert_response :redirect
  end

  test "new reward is blocked when not authorized" do
    article = articles(:published_paid)
    sign_in(users(:reader_one))

    get new_pre_order_path(article_uuid: article.uuid, order_type: "reward_article")

    assert_response :redirect
  end

  test "paid pre_order resolves article redirect path" do
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

      redirect_url = user_article_path(article.author, article)

      assert pre_order.paid?
      assert_includes redirect_url, article.uuid
    end
  end
end
