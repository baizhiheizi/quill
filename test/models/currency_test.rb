# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
# Database name: primary
#
#  id         :bigint           not null, primary key
#  price_btc  :decimal(, )
#  price_usd  :decimal(, )
#  raw        :jsonb
#  symbol     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  chain_id   :uuid
#
# Indexes
#
#  index_currencies_on_asset_id  (asset_id) UNIQUE
#

require "test_helper"

class CurrencyTest < ActiveSupport::TestCase
  setup do
    @btc = currencies(:btc)
  end

  test "exposes the well-known asset id constants" do
    assert_equal "c6d0c728-2624-429b-8e0d-d9d19b6592fa", Currency::BTC_ASSET_ID
    assert_equal "0ff3f325-4f34-334d-b6c0-a3bd8850fc06", Currency::JPYC_ASSET_ID
    assert_equal "31d2ea9c-95eb-3355-b65b-ba096853bc18", Currency::PUSD_ASSET_ID
    assert_equal "c94ac88f-4671-3976-b60a-09064f1811e8", Currency::XIN_ASSET_ID
    assert_equal "43d61dcd-e413-450d-80b8-101d5e903357", Currency::ETH_ASSET_ID
  end

  test "btc scope returns the bitcoin currency" do
    assert_equal @btc, Currency.btc
  end

  test "pricable? returns true when the asset is in Article::SUPPORTED_ASSETS" do
    assert_predicate @btc, :pricable?
  end

  test "pricable? returns false for an unsupported asset" do
    @btc.asset_id = SecureRandom.uuid
    assert_not @btc.pricable?
  end

  test "minimal_reward_amount returns the usd-derived amount when price_usd is positive" do
    # 0.5 USD at 50_000 USD/BTC = 0.00001 BTC, rounded up to 8 decimals
    assert_equal BigDecimal("0.00001"), @btc.minimal_reward_amount
  end

  test "minimal_reward_amount falls back to symbol defaults when price_usd is zero" do
    @btc.price_usd = 0
    assert_equal 0.00005, @btc.minimal_reward_amount
  end

  test "minimal_price_amount returns the usd-derived amount when price_usd is positive" do
    # 0.1 USD at 50_000 USD/BTC = 0.000002 BTC, rounded up to 8 decimals
    assert_equal BigDecimal("0.000002"), @btc.minimal_price_amount
  end

  test "minimal_price_amount honors the requested target price" do
    # 1.0 USD at 50_000 USD/BTC = 0.00002 BTC, rounded up to 8 decimals
    assert_equal BigDecimal("0.00002"), @btc.minimal_price_amount(1.0)
  end

  test "minimal_price_amount falls back to symbol defaults when price_usd is zero" do
    @btc.price_usd = 0
    assert_equal 0.00001, @btc.minimal_price_amount
  end

  test "icon_url returns only absolute http(s) urls" do
    assert_equal "https://example.com/btc.png", @btc.icon_url

    @btc.raw = @btc.raw.merge("icon_url" => "icon_url")
    assert_nil @btc.icon_url

    @btc.raw = @btc.raw.except("icon_url")
    assert_nil @btc.icon_url
  end
end
