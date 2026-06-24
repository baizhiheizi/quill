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

class PreOrdersCreateControllerTest < ActionController::TestCase
  tests PreOrdersController

  include QuillBotStub

  setup do
    @article = articles(:published_paid)
    @buyer = users(:reader_one)
    session[:current_session_id] = Session.create!(
      user: @buyer,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    Rails.cache.write("mixpay_settlement_asset_ids", [], expires_in: 10.minutes)
  end

  test "create mixin buy article saves pre_order and renders payment modal" do
    with_quill_bot_stub do
      assert_difference "MixinPreOrder.count", 1 do
        post :create, params: {
          pre_order: {
            order_type: "buy_article",
            item_id: @article.id,
            item_type: "Article",
            asset_id: @article.asset_id,
            amount: @article.price,
            type: "MixinPreOrder"
          }
        }, format: :turbo_stream
      end
    end

    assert_response :success
    assert_includes @response.body, "pre-orders-payment-component"
  end
end
