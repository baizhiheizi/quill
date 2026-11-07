# frozen_string_literal: true

require "test_helper"

class MixpayPreOrdersControllerTest < ActionController::TestCase
  tests MixpayPreOrdersController

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
    # Default: BTC is settlement-supported, and a quote asset that allows the
    # paid article's amount range (0.0001 BTC, well within min=0 / max=1).
    mixpay_api.define_singleton_method(:settlement_asset_ids) do
      [ Currency::BTC_ASSET_ID ]
    end
    mixpay_api.define_singleton_method(:quote_assets_cached) do
      [ { "assetId" => Currency::BTC_ASSET_ID, "minQuoteAmount" => "0", "maxQuoteAmount" => "1" } ]
    end
    Mixpay.instance_variable_set(:@api, mixpay_api)
  end

  teardown do
    Mixpay.instance_variable_set(:@api, @original_mixpay_api)
  end

  test "show requires a signed-in reader" do
    session.delete(:current_session_id)

    get :show, params: { order_type: "buy_article", item_id: @article.id, item_type: "Article" }

    assert_response :redirect
  end

  test "show saves and redirects to the mixpay pay url for a supported article" do
    assert_difference "PreOrder.count", 1 do
      get :show, params: {
        order_type: "buy_article",
        item_id: @article.id,
        item_type: "Article",
        asset_id: @article.asset_id,
        amount: @article.price
      }
    end

    pre_order = PreOrder.order(:id).last
    assert_equal "MixpayPreOrder", pre_order.type
    assert_redirected_to %r{\Ahttps://mixpay\.me/pay}
  end

  # The mixpay button encodes the item's class and id in the query string,
  # so a stale page or a crafted link can name an item that no longer
  # exists. The failed save used to fall through to `@pre_order.item.author`,
  # and reading that association raised ActiveRecord::RecordNotFound -> 500.
  test "show redirects home for an unknown item id" do
    assert_no_difference "PreOrder.count" do
      get :show, params: { order_type: "buy_article", item_id: Article.maximum(:id).to_i + 1, item_type: "Article" }
    end

    assert_redirected_to root_path
  end

  # No item_type/item_id at all: the pre-order fails its belongs_to
  # validation, and the failure branch used to read `@pre_order.item.author`
  # on nil -> NoMethodError -> 500.
  test "show redirects home when the item params are missing" do
    assert_no_difference "PreOrder.count" do
      get :show, params: { order_type: "buy_article" }
    end

    assert_redirected_to root_path
  end

  # A garbage `item_type` used to be constantized by the item association's
  # polymorphic load -> NameError -> 500.
  test "show redirects home for an unknown item type" do
    assert_no_difference "PreOrder.count" do
      get :show, params: { order_type: "buy_article", item_id: @article.id, item_type: "not_a_class" }
    end

    assert_redirected_to root_path
  end

  # With a valid item, a failed save (amount = 0 fails numericality) falls
  # through to the article page, where the reader can retry.
  test "show redirects to the article page when the save fails on a valid article" do
    assert_no_difference "PreOrder.count" do
      get :show, params: {
        order_type: "buy_article",
        item_id: @article.id,
        item_type: "Article",
        asset_id: @article.asset_id,
        amount: 0
      }
    end

    assert_redirected_to user_article_path(@article.author, @article)
  end

  # The failure branch used to send collections to
  # `user_article_path(author, collection)` — an article URL built with a
  # collection as the article, which 404s. The collection flow now gets the
  # collection page, mirroring PreOrdersController#show.
  test "show redirects to the collection page when the save fails on a valid collection" do
    collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Mixpay Show Test Collection",
      symbol: "MSTC",
      description: "For mixpay_pre_order controller failure-path test",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )

    assert_no_difference "PreOrder.count" do
      get :show, params: {
        order_type: "buy_collection",
        item_id: collection.id,
        item_type: "Collection",
        asset_id: collection.asset_id,
        amount: 0
      }
    end

    assert_redirected_to collection_path(collection.uuid)
  end
end
