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

    @original_mixpay_api = Mixpay.instance_variable_get(:@api)
    mixpay_api = Object.new
    mixpay_api.define_singleton_method(:settlement_asset_ids) { [] }
    mixpay_api.define_singleton_method(:quote_assets_cached) { [] }
    Mixpay.instance_variable_set(:@api, mixpay_api)
  end

  teardown do
    Mixpay.instance_variable_set(:@api, @original_mixpay_api)
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

  test "create mixin buy article succeeds when currency icon_url is missing" do
    @article.currency.update_column(:raw, @article.currency.raw.except("icon_url"))

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

  # Fennec/mvm_eth login was removed, but those users and their
  # `UserAuthorization` rows are kept (see #1795). Without this guard,
  # `default_payment` returns nil for them and the buy/reward forms would
  # submit a blank `pre_order[type]`, silently creating a base `PreOrder`
  # whose `type` is nil — which later raises `NoMethodError` (`nil.underscore`)
  # in `PreOrder#broadcast_to_views` once the payment is confirmed.
  test "new redirects to login for a user with no working payment provider" do
    legacy_user = User.create!(
      name: "Legacy Fennec",
      mixin_id: "fennec-legacy",
      mixin_uuid: SecureRandom.uuid,
      uid: "fennec-legacy"
    )
    UserAuthorization.create!(user: legacy_user, provider: :fennec, uid: "fennec-legacy-uid", raw: { "user_id" => "fennec-legacy-uid" })
    session[:current_session_id] = Session.create!(user: legacy_user, uuid: SecureRandom.uuid, info: { "provider" => "mixin" }).uuid

    get :new, params: { article_uuid: @article.uuid, order_type: "buy_article" }

    assert_redirected_to login_path
  end

  test "create redirects to login without saving a pre_order for a user with no working payment provider" do
    legacy_user = User.create!(
      name: "Legacy MVM",
      mixin_id: "mvm-legacy",
      mixin_uuid: SecureRandom.uuid,
      uid: "mvm-legacy"
    )
    UserAuthorization.create!(user: legacy_user, provider: :mvm_eth, uid: "mvm-legacy-uid", raw: { "user_id" => "mvm-legacy-uid" })
    session[:current_session_id] = Session.create!(user: legacy_user, uuid: SecureRandom.uuid, info: { "provider" => "mixin" }).uuid

    assert_no_difference "PreOrder.count" do
      post :create, params: {
        pre_order: {
          order_type: "buy_article",
          item_id: @article.id,
          item_type: "Article",
          asset_id: @article.asset_id,
          amount: @article.price
        }
      }
    end

    assert_redirected_to login_path
  end
end
