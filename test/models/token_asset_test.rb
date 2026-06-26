# frozen_string_literal: true

require "test_helper"

class TokenAssetTest < ActiveSupport::TestCase
  setup do
    @btc = currencies(:btc)
  end

  # ----- balance computation (decimal scaling from raw on-chain values) -----

  test "balance divides raw balance by 10^decimals" do
    asset = TokenAsset.new(
      owner: nil,
      currency: @btc,
      token: { "balance" => "100000000", "decimals" => 8 }
    )
    assert_in_delta 1.0, asset.balance, 1.0e-9
  end

  test "balance handles 18-decimal ERC-20 tokens" do
    asset = TokenAsset.new(
      owner: nil,
      currency: @btc,
      token: { "balance" => (10**18).to_s, "decimals" => 18 }
    )
    assert_in_delta 1.0, asset.balance, 1.0e-9
  end

  test "balance rounds to 8 decimal places" do
    asset = TokenAsset.new(
      owner: nil,
      currency: @btc,
      token: { "balance" => "1", "decimals" => 8 }
    )
    # 1 / 10^8 = 0.00000001 — fits in 8 decimal places
    assert_in_delta 1.0e-8, asset.balance, 1.0e-16
  end

  test "balance is zero when token is nil" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_equal 0, asset.balance
  end

  test "balance is zero when token is an empty hash" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: {})
    assert_equal 0, asset.balance
  end

  test "balance is zero when raw balance is the string '0'" do
    asset = TokenAsset.new(
      owner: nil,
      currency: @btc,
      token: { "balance" => "0", "decimals" => 8 }
    )
    assert_equal 0, asset.balance
  end

  # ----- balance_usd computation -----

  test "balance_usd multiplies balance by currency price_usd" do
    # btc fixture: price_usd = 50_000.0
    asset = TokenAsset.new(
      owner: nil,
      currency: @btc,
      token: { "balance" => "100000000", "decimals" => 8 } # 1 BTC
    )
    assert_equal 50_000.0, asset.balance_usd
  end

  test "balance_usd is zero when balance is zero" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_equal 0, asset.balance_usd
  end

  test "balance_usd rounds to 4 decimal places" do
    # Build an in-memory currency with a non-round price to exercise the
    # 4-decimal-place rounding in `(@balance * currency.price_usd.to_f).round(4)`.
    # Avoids Currency#save, which would trip the before_validation callback
    # that calls QuillBot.api.asset(asset_id).
    custom = Currency.new(price_usd: 0.123456789)
    asset = TokenAsset.new(
      owner: nil,
      currency: custom,
      token: { "balance" => "1000000", "decimals" => 8 } # 0.01 BTC
    )
    # 0.01 * 0.123456789 = 0.00123456789 → round(4) = 0.0012
    assert_in_delta 0.0012, asset.balance_usd, 1.0e-9
  end

  # ----- delegated currency accessors -----

  test "delegates asset_id to currency" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_equal @btc.asset_id, asset.asset_id
  end

  test "delegates symbol to currency" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_equal "BTC", asset.symbol
  end

  test "delegates price_usd to currency" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_in_delta 50_000.0, asset.price_usd, 1.0e-9
  end

  test "delegates price_btc to currency" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_in_delta 1.0, asset.price_btc, 1.0e-9
  end

  test "delegates chain_id to currency" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    # btc fixture does not set chain_id
    assert_nil asset.chain_id
  end

  # ----- constructor argument pass-through -----

  test "exposes the owner it was constructed with" do
    fake_owner = Object.new
    asset = TokenAsset.new(owner: fake_owner, currency: @btc, token: nil)
    assert_same fake_owner, asset.owner
  end

  test "exposes the token it was constructed with" do
    token = { "balance" => "1", "decimals" => 0 }
    asset = TokenAsset.new(owner: nil, currency: @btc, token: token)
    assert_same token, asset.token
  end

  test "exposes the currency it was constructed with" do
    asset = TokenAsset.new(owner: nil, currency: @btc, token: nil)
    assert_same @btc, asset.currency
  end
end
