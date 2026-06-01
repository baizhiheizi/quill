# frozen_string_literal: true

require "test_helper"

class CollectionPolicyTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @reader = users(:reader_one)
    @collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Policy Test Collection",
      symbol: "PTC",
      description: "Collection for policy tests",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end

  test "show? allows author" do
    assert CollectionPolicy.new(@author, @collection).show?
  end

  test "show? allows published collection to readers" do
    assert CollectionPolicy.new(@reader, @collection).show?
  end

  test "show? denies readers when collection is not published" do
    @collection.update!(uuid: nil, state: "drafted")

    refute CollectionPolicy.new(@reader, @collection).show?
  end

  test "update? allows author only" do
    assert CollectionPolicy.new(@author, @collection).update?
    refute CollectionPolicy.new(@reader, @collection).update?
  end

  test "purchase? allows readers who have not bought" do
    assert CollectionPolicy.new(@reader, @collection).purchase?
  end

  test "purchase? denies buyers who already own the collection" do
    with_quill_bot_stub do
      create_payment!(
        payer: @reader,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
    end

    refute CollectionPolicy.new(@reader, @collection).purchase?
  end
end
