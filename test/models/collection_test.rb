# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  description            :text
#  name                   :string
#  orders_count           :integer          default(0)
#  platform_revenue_ratio :float            default(0.1)
#  price                  :decimal(, )
#  revenue_ratio          :float            default(0.2)
#  state                  :string
#  symbol                 :string
#  uuid                   :uuid
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  asset_id               :uuid
#  author_id              :uuid
#
# Indexes
#
#  index_collections_on_author_id  (author_id)
#  index_collections_on_uuid       (uuid) UNIQUE
#
require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "authorized? allows author" do
    collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Test Collection",
      symbol: "TC",
      description: "Test collection description",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )

    assert collection.authorized?(users(:author))
  end

  test "authorized? allows buyer with order" do
    collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Buyer Collection",
      symbol: "BC",
      description: "Buyer collection description",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
    buyer = users(:reader_one)

    with_quill_bot_stub do
      payment = create_payment!(
        payer: buyer,
        collection: collection,
        order_type: "BUY",
        amount: collection.price
      )
      assert payment.order.present?
      assert collection.authorized?(buyer)
    end
  end

  test "publish! creates nft_collection and lists drafted collection" do
    collection = Collection.create!(
      name: "Publish Collection",
      symbol: "PC",
      description: "Publish collection description",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "drafted"
    )

    collection.define_singleton_method(:generate_cover) { }

    collection.publish!

    assert collection.published?
    assert collection.listed?
    assert collection.nft_collection.present?
  end

  test "authorized? denies strangers" do
    collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Private Collection",
      symbol: "PC",
      description: "Private collection description",
      author: users(:author),
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )

    assert_not collection.authorized?(users(:reader_one))
  end
end
