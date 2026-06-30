# frozen_string_literal: true

require "test_helper"

# Covers the `Users::MVMQueriable` concern shared by `User`.
#
# Public surface tested:
#
# - `tokens_erc721` — returns `[]` unless the user is signed in via MVM
#   (`mvm_eth?`), otherwise fetches `MVM.scan.tokens(uid, type: "ERC-721")`
#   through `Rails.cache.fetch` keyed by `"#{uid}_tokens_erc721"` for
#   3 minutes.
#
# - `tokens_erc20` — same shape as `tokens_erc721` but for `"ERC-20"`,
#   keyed `"#{uid}_tokens_erc20"`.
#
# - `token_assets` — returns `nil` unless `mvm_eth?`. Iterates
#   `Currency.all`, builds a `TokenAsset` per currency using the user's
#   ERC-20 holdings (matched by `contractAddress == mvm_contract_address`),
#   filters to `balance.positive? || asset_id.in?(Settings.supported_assets)`,
#   and sorts descending by `balance_usd`.
#
# Why a dedicated file: the concern couples three external surfaces —
# the MVM scan service, the Rails cache, and the global `Currency.all`
# list — and ships zero test coverage. `test/models/user_test.rb` focuses
# on user validations and authorization wiring, not the MVM path; the
# mvm_eth branches there are simply unreachable without a stubbed scan.
#
# Stubbing notes: this codebase runs on Minitest 6.0.6, which removed
# `Object#stub`. We therefore use `define_singleton_method` + `ensure`
# to swap class-level methods (`Currency.all`, `Settings.supported_assets`)
# for the duration of a test. The `MVM.scan` swap is centralised in
# `stub_scan_tokens` below so the same pattern is reused across the
# `tokens_erc721` / `tokens_erc20` / `token_assets` branches.
class Users::MVMQueriableTest < ActiveSupport::TestCase
  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
    @previous_cache = Rails.cache
    Rails.cache = @cache

    @mvm_user = User.create!(
      uid: "300099",
      name: "MVM Queriable Reader",
      mixin_id: "300099",
      mixin_uuid: "e9999999-9999-4999-8999-999999999999",
      locale: :en
    )
    @mvm_user.user_authorizations.create!(
      provider: :mvm_eth,
      uid: "0xmvmqueriable",
      raw: { "user_id" => "0xmvmqueriable" }
    )
  end

  teardown do
    Rails.cache = @previous_cache
  end

  # Stub MVM.scan.tokens so the concern's network path is replaced by a
  # frozen array. The block runs once; the cache keeps the response for
  # the rest of the test.
  def stub_scan_tokens(value)
    fake_scan = Class.new do
      def initialize(value)
        @value = value
      end

      def tokens(_uid, type:)
        @value.select { |t| t["type"] == type }
      end
    end.new(value)

    original = MVM.instance_variable_get(:@scan)
    MVM.instance_variable_set(:@scan, fake_scan)
    yield
  ensure
    MVM.instance_variable_set(:@scan, original)
  end

  # Temporarily swap `Currency.all` for a fixed array, restoring it on
  # the way out. Avoids `Currency.where(...)` / fixture churn for the
  # dozen branches `token_assets` exposes.
  def with_currency_all(value)
    original = Currency.method(:all)
    Currency.define_singleton_method(:all) { value }
    yield
  ensure
    Currency.define_singleton_method(:all, original)
  end

  # Temporarily swap `Settings.supported_assets`, restoring it on the
  # way out.
  def with_supported_assets(value)
    original = Settings.method(:supported_assets)
    Settings.define_singleton_method(:supported_assets) { value }
    yield
  ensure
    Settings.define_singleton_method(:supported_assets, original)
  end

  # --- gate predicate: mvm_eth? ---

  test "mvm_eth? is true for a user whose authorization provider is mvm_eth" do
    assert @mvm_user.mvm_eth?
  end

  test "mvm_eth? is false for a user whose authorization provider is mixin" do
    assert_not users(:author).mvm_eth?
  end

  # --- tokens_erc721 ---

  test "tokens_erc721 returns [] when the user is not an mvm_eth user" do
    assert_equal [], users(:author).tokens_erc721
  end

  test "tokens_erc721 returns the ERC-721 subset from MVM.scan" do
    all_tokens = [
      { "type" => "ERC-721", "contractAddress" => "0xnft" },
      { "type" => "ERC-20",  "contractAddress" => "0xerc20" }
    ]

    stub_scan_tokens(all_tokens) do
      result = @mvm_user.tokens_erc721

      assert_equal [ { "type" => "ERC-721", "contractAddress" => "0xnft" } ], result
    end
  end

  test "tokens_erc721 caches the MVM.scan response for 3 minutes" do
    first = [ { "type" => "ERC-721", "contractAddress" => "0xfirst" } ]
    second = [ { "type" => "ERC-721", "contractAddress" => "0xsecond" } ]

    # Prime the cache with the first response.
    stub_scan_tokens(first) do
      assert_equal first, @mvm_user.tokens_erc721
    end

    # Without the cache the scan would return `second`; with it we still
    # see the first response.
    stub_scan_tokens(second) do
      assert_equal first, @mvm_user.tokens_erc721
    end
  end

  test "tokens_erc721 memoizes the result on the same instance" do
    stub_scan_tokens([]) do
      first = @mvm_user.tokens_erc721
      second = @mvm_user.tokens_erc721

      assert_same first, second, "expected the second call to return the memoized array"
    end
  end

  test "tokens_erc721 caches under the key uid_tokens_erc721" do
    stub_scan_tokens([ { "type" => "ERC-721", "contractAddress" => "0xkey" } ]) do
      @mvm_user.tokens_erc721

      assert @cache.exist?("#{@mvm_user.uid}_tokens_erc721"),
        "expected cache key #{@mvm_user.uid}_tokens_erc721 to be written"
    end
  end

  test "tokens_erc721 caches under the uid (not the mixin_uuid)" do
    stub_scan_tokens([ { "type" => "ERC-721", "contractAddress" => "0xkey" } ]) do
      @mvm_user.tokens_erc721

      assert_not @cache.exist?("#{@mvm_user.mixin_uuid}_tokens_erc721"),
        "concern must key the cache by uid, not mixin_uuid"
    end
  end

  # --- tokens_erc20 ---

  test "tokens_erc20 returns [] when the user is not an mvm_eth user" do
    assert_equal [], users(:author).tokens_erc20
  end

  test "tokens_erc20 returns the ERC-20 subset from MVM.scan" do
    all_tokens = [
      { "type" => "ERC-721", "contractAddress" => "0xnft" },
      { "type" => "ERC-20",  "contractAddress" => "0xerc20" }
    ]

    stub_scan_tokens(all_tokens) do
      result = @mvm_user.tokens_erc20

      assert_equal [ { "type" => "ERC-20", "contractAddress" => "0xerc20" } ], result
    end
  end

  test "tokens_erc20 caches the MVM.scan response for 3 minutes" do
    first = [ { "type" => "ERC-20", "contractAddress" => "0xfirst" } ]
    second = [ { "type" => "ERC-20", "contractAddress" => "0xsecond" } ]

    stub_scan_tokens(first) do
      assert_equal first, @mvm_user.tokens_erc20
    end

    stub_scan_tokens(second) do
      assert_equal first, @mvm_user.tokens_erc20
    end
  end

  test "tokens_erc20 caches under the key uid_tokens_erc20" do
    stub_scan_tokens([ { "type" => "ERC-20", "contractAddress" => "0xkey" } ]) do
      @mvm_user.tokens_erc20

      assert @cache.exist?("#{@mvm_user.uid}_tokens_erc20")
    end
  end

  test "tokens_erc721 and tokens_erc20 cache entries are independent" do
    stub_scan_tokens([
      { "type" => "ERC-721", "contractAddress" => "0xnft" },
      { "type" => "ERC-20",  "contractAddress" => "0xerc20" }
    ]) do
      @mvm_user.tokens_erc721
      @mvm_user.tokens_erc20

      assert @cache.exist?("#{@mvm_user.uid}_tokens_erc721")
      assert @cache.exist?("#{@mvm_user.uid}_tokens_erc20")
    end
  end

  # --- token_assets ---

  test "token_assets returns nil when the user is not an mvm_eth user" do
    assert_nil users(:author).token_assets
  end

  test "token_assets pairs each Currency with the matching ERC-20 token" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")
    eth = Currency.new(asset_id: "43d61dcd-e413-450d-80b8-101d5e903357", price_usd:    3_000.0, symbol: "ETH", mvm_contract_address: "0xeth")

    stub_scan_tokens([
      { "type" => "ERC-20",  "contractAddress" => "0xbtc", "balance" => (1 * 10**8).to_s,  "decimals" => 8 },
      { "type" => "ERC-20",  "contractAddress" => "0xeth", "balance" => (2 * 10**18).to_s, "decimals" => 18 },
      { "type" => "ERC-721", "contractAddress" => "0xnft" }
    ]) do
      with_currency_all([ btc, eth ]) do
        assets = @mvm_user.token_assets

        assert_equal 2, assets.size
        assert_equal [ btc, eth ], assets.map(&:currency)
        assert_equal [ 1.0, 2.0 ], assets.map(&:balance)
        assert_equal [ 50_000.0, 6_000.0 ], assets.map(&:balance_usd)
      end
    end
  end

  test "token_assets uses balance 0 when the user does not hold a given Currency" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")
    eth = Currency.new(asset_id: "43d61dcd-e413-450d-80b8-101d5e903357", price_usd:    3_000.0, symbol: "ETH", mvm_contract_address: "0xeth")

    # User holds BTC only; ETH is whitelisted via Settings.supported_assets
    # so it survives the concern's zero-balance filter with balance 0.
    stub_scan_tokens([
      { "type" => "ERC-20", "contractAddress" => "0xbtc", "balance" => (1 * 10**8).to_s, "decimals" => 8 }
    ]) do
      with_currency_all([ btc, eth ]) do
        with_supported_assets([ btc.asset_id, eth.asset_id ]) do
          eth_asset = @mvm_user.token_assets.find { |a| a.currency == eth }

          assert_equal 0, eth_asset.balance
          assert_equal 0.0, eth_asset.balance_usd
        end
      end
    end
  end

  test "token_assets filters out zero-balance currencies that are not in Settings.supported_assets" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")
    eth = Currency.new(asset_id: "43d61dcd-e413-450d-80b8-101d5e903357", price_usd:    3_000.0, symbol: "ETH", mvm_contract_address: "0xeth")

    stub_scan_tokens([
      { "type" => "ERC-20", "contractAddress" => "0xbtc", "balance" => (1 * 10**8).to_s, "decimals" => 8 }
    ]) do
      with_currency_all([ btc, eth ]) do
        with_supported_assets([ btc.asset_id ]) do
          assets = @mvm_user.token_assets

          assert_equal [ btc ], assets.map(&:currency),
            "ETH holds zero balance and is not in Settings.supported_assets — should be filtered out"
        end
      end
    end
  end

  test "token_assets keeps zero-balance currencies when their asset_id is in Settings.supported_assets" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")

    # User holds zero BTC; btc is still in supported_assets.
    stub_scan_tokens([]) do
      with_currency_all([ btc ]) do
        with_supported_assets([ btc.asset_id ]) do
          assets = @mvm_user.token_assets

          assert_equal [ btc ], assets.map(&:currency)
          assert_equal 0, assets.first.balance
        end
      end
    end
  end

  test "token_assets sorts results by descending balance_usd" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")
    eth = Currency.new(asset_id: "43d61dcd-e413-450d-80b8-101d5e903357", price_usd:    3_000.0, symbol: "ETH", mvm_contract_address: "0xeth")

    stub_scan_tokens([
      { "type" => "ERC-20", "contractAddress" => "0xbtc", "balance" => (1 * 10**8).to_s,  "decimals" => 8 },   # 50_000 USD
      { "type" => "ERC-20", "contractAddress" => "0xeth", "balance" => (5 * 10**18).to_s, "decimals" => 18 }   # 15_000 USD
    ]) do
      with_currency_all([ eth, btc ]) do
        with_supported_assets([ btc.asset_id, eth.asset_id ]) do
          assets = @mvm_user.token_assets

          assert_equal [ btc, eth ], assets.map(&:currency),
            "expected descending balance_usd order regardless of Currency.all order"
        end
      end
    end
  end

  test "token_assets memoizes the result on the same instance" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")

    stub_scan_tokens([
      { "type" => "ERC-20", "contractAddress" => "0xbtc", "balance" => (1 * 10**8).to_s, "decimals" => 8 }
    ]) do
      with_currency_all([ btc ]) do
        first = @mvm_user.token_assets
        second = @mvm_user.token_assets

        assert_same first, second, "expected the second call to return the memoized array"
      end
    end
  end

  test "token_assets ignores ERC-721 entries when matching contract addresses" do
    btc = Currency.new(asset_id: "c6d0c728-2624-429b-8e0d-d9d19b6592fa", price_usd: 50_000.0, symbol: "BTC", mvm_contract_address: "0xbtc")

    # The ERC-721 entry's contract address matches BTC's mvm_contract_address,
    # but token_assets only walks the ERC-20 list, so the BTC row should
    # receive a balance of 0 (and stay visible via Settings.supported_assets).
    stub_scan_tokens([
      { "type" => "ERC-721", "contractAddress" => "0xbtc", "balance" => "1", "decimals" => 0 }
    ]) do
      with_currency_all([ btc ]) do
        with_supported_assets([ btc.asset_id ]) do
          assets = @mvm_user.token_assets

          assert_equal [ btc ], assets.map(&:currency)
          assert_equal 0, assets.first.balance
        end
      end
    end
  end
end
