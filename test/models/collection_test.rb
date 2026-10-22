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

  test "publish! lists drafted collection" do
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

  # === asset selection ===

  test "a collection priced in a supported asset is valid" do
    collection = Collection.new(
      uuid: SecureRandom.uuid,
      name: "Ether Collection",
      symbol: "EC",
      description: "A collection priced in ether.",
      author: users(:author),
      asset_id: currencies(:eth).asset_id,
      price: BigDecimal("0.01"),
      revenue_ratio: 0.1,
      state: "listed"
    )

    assert collection.valid?
    assert_equal currencies(:eth), collection.currency
  end

  test "a collection priced in an asset without a currency row is invalid instead of raising" do
    collection = Collection.new(
      uuid: SecureRandom.uuid,
      name: "Unknown Asset Collection",
      symbol: "UC",
      description: "A collection pointing at an asset the currency sync has not seen.",
      author: users(:author),
      asset_id: SecureRandom.uuid,
      price: BigDecimal("0.01"),
      revenue_ratio: 0.1,
      state: "listed"
    )

    # `belongs_to :currency` is required, so the missing row surfaces as a
    # validation error. It used to raise NoMethodError (HTTP 500) from
    # `ensure_price_not_too_low`.
    assert_nothing_raised { collection.valid? }
    assert_not collection.valid?
    assert_includes collection.errors.full_messages, "Currency must exist"
  end
end
