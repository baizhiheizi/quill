# frozen_string_literal: true

require "test_helper"

class CollectionsControllerTest < IntegrationTestCase
  setup do
    @collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Public Collection",
      symbol: "PC",
      description: "Collection show page test",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end

  test "show succeeds when currency icon_url is missing" do
    @collection.currency.update_column(:raw, @collection.currency.raw.except("icon_url"))

    get collection_path(@collection.uuid)

    assert_response :success
  end

  test "show succeeds when currency icon_url is invalid" do
    @collection.currency.update_column(:raw, @collection.currency.raw.merge("icon_url" => "icon_url"))

    get collection_path(@collection.uuid)

    assert_response :success
  end
end
