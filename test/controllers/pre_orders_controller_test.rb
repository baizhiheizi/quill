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

  # The `new` action is exercised as a controller test below
  # (`PreOrdersNewControllerTest`): an integration session does not carry
  # the signed-in reader here, and `ApplicationController#authenticate_user!`
  # redirects an anonymous visitor to `root_path` as well.
end

# `PreOrdersController#new` and `#show` are exercised as a controller test
# (rather than through the integration session) so the signed-in reader is
# explicit: `ApplicationController#authenticate_user!` redirects an
# anonymous visitor to `root_path` as well, which would make every
# "redirects home" assertion pass for the wrong reason.
class PreOrdersNewControllerTest < ActionController::TestCase
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

    with_quill_bot_stub do
      create_buy_order!(article: @article, buyer: @buyer)
    end
  end

  # A reader who bought the article is authorized to reward it, so the
  # modal form renders. The regression tests below are measured against
  # this happy path.
  test "new renders the reward form for a reader who bought the article" do
    get :new, params: { article_uuid: @article.uuid, order_type: "reward_article" }

    assert_response :success
  end

  # An unknown or unpublished `article_uuid` used to hit a bare `return` in
  # `PreOrdersController#new`. Rails then rendered `pre_orders/new` with
  # `@pre_order` still nil, and the view raised
  # `undefined method 'item' for nil` -> HTTP 500.
  test "new redirects home for an unknown article" do
    get :new, params: { article_uuid: SecureRandom.uuid, order_type: "reward_article" }

    assert_redirected_to root_path
  end

  # `order_type` reached the view unvalidated: an unsupported value skipped
  # `authorize_pre_order_item!` entirely and made the price helper return
  # nil, so the form raised `can't convert nil into Float` -> HTTP 500.
  test "new redirects home for an unsupported order type" do
    get :new, params: { article_uuid: @article.uuid, order_type: "cite_article" }

    assert_redirected_to root_path
  end

  # `new` only ever resolves an Article, but `PreOrder.order_types` also
  # contains `buy_collection`. Accepting it here rendered the buy-collection
  # form for an Article, and submitting it saved a pre-order whose on-chain
  # memo put the ARTICLE's uuid in the collection slot
  # (`Mixin::Memo.buy!(collection: item, ...)`) — a protocol violation.
  # `buy_collection` belongs to the Collection flow, which posts straight to
  # `create`.
  #
  # The reader used here has NOT bought the article, so `authorize item,
  # :purchase?` succeeds: before the fix the buy-collection form rendered
  # (HTTP 200) instead of redirecting.
  test "new redirects home for the buy_collection order type" do
    buyer = users(:reader_two)
    session[:current_session_id] = Session.create!(
      user: buyer,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    assert_no_difference "PreOrder.count" do
      get :new, params: { article_uuid: @article.uuid, order_type: "buy_collection" }
    end

    assert_redirected_to root_path
  end

  # The turbo stream is the format the pay button's Stimulus controller
  # requests. An unknown `follow_id` left `@pre_order` nil and `dom_id(nil)`
  # raised `ArgumentError` -> HTTP 500.
  test "show redirects home for an unknown pre order in the turbo stream format" do
    get :show, params: { follow_id: SecureRandom.uuid }, format: :turbo_stream

    assert_redirected_to root_path
  end

  # `pay_asset_id` comes straight from the query string. An unknown value —
  # or an empty string, which is truthy and so does not fall back — used to
  # make `Currency.find_by` return nil and raise `undefined method
  # 'asset_id' for nil` -> HTTP 500.
  test "show falls back to the pre order currency for an unknown pay asset" do
    with_quill_bot_stub do
      pre_order = PreOrder.create!(
        item: @article,
        payer: @buyer,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      get :show, params: { follow_id: pre_order.follow_id, pay_asset_id: "not-an-asset" }, format: :turbo_stream
    end

    assert_response :success
  end

  # The turbo stream template compares the resolved `pay_asset` local with
  # the pre order's currency to choose between the "≈$ <usd>" estimate and
  # the "≈ <amount> <SYMBOL>" one. The comparison used the never-assigned
  # `@pay_asset` ivar, so the USD variant was dead code and the template
  # always rendered the asset amount.
  test "show renders the usd estimate when the pay asset matches the pre order currency" do
    with_quill_bot_stub do
      pre_order = PreOrder.create!(
        item: @article,
        payer: @buyer,
        order_type: :buy_article,
        amount: @article.price,
        asset_id: @article.asset_id
      )

      get :show, params: { follow_id: pre_order.follow_id }, format: :turbo_stream
    end

    assert_response :success
    assert_includes @response.body, "≈$",
      "expected the USD estimate for a pay asset matching the pre order currency"
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
