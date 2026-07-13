# frozen_string_literal: true

require "test_helper"

class Collections::BaseControllerTest < ActionDispatch::IntegrationTest
  # Public-side base-controller regression guard. Consumed via the
  # `Collections::ArticlesController` and `Collections::SubscribersController`
  # children (`/collections/:collection_uuid/articles`,
  # `/collections/:collection_uuid/subscribers`).
  #
  # `Collections::BaseController#load_collection` resolves the collection
  # by `params[:collection_uuid]` and renders a 404 unless the collection
  # is `listed?` (AASM `state == "listed"`). Without these tests, the
  # 404 path is the only way to discover this guard has regressed.
  setup do
    @author = users(:author)
    @listed = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Listed Collection",
      symbol: "LC",
      description: "Listed",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
    @drafted = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Drafted Collection",
      symbol: "DC",
      description: "Drafted",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "drafted"
    )
    @hidden = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Hidden Collection",
      symbol: "HC",
      description: "Hidden",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "hidden"
    )
  end

  test "load_collection returns 200 for a listed collection" do
    get collection_articles_path(collection_uuid: @listed.uuid)

    assert_response :success
  end

  test "load_collection returns 404 for a missing collection uuid" do
    get collection_articles_path(collection_uuid: SecureRandom.uuid)

    assert_response :not_found
  end

  test "load_collection returns 404 for a drafted collection" do
    get collection_articles_path(collection_uuid: @drafted.uuid)

    assert_response :not_found
  end

  test "load_collection returns 404 for a hidden collection" do
    get collection_articles_path(collection_uuid: @hidden.uuid)

    assert_response :not_found
  end
end
