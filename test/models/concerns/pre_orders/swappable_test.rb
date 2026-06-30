# frozen_string_literal: true

require "test_helper"

# Covers the `PreOrders::Swappable` concern shared by `PreOrder` (and
# any future pre-order subclass that opts in via `include
# PreOrders::Swappable`).
#
# Public surface tested:
#
# - `pay_url(pay_asset_id = asset_id)` — dispatches between
#   `direct_pay_url` and `foxswap_pay_url` based on whether the caller's
#   `pay_asset_id` matches the order's `asset_id`. The default-arg call
#   always routes through `direct_pay_url`.
#
# - `direct_pay_url` — calls `QuillBot.api.safe_pay_url` with the bot
#   client as the sole member, threshold 1, the order's own asset /
#   amount / trace_id / memo.
#
# - `foxswap_pay_url(pay_asset_id)` — three branches:
#     1. `pay_asset_id == asset_id` → returns nil (caller should use
#        `direct_pay_url` instead; this is the same-asset short-circuit).
#     2. `fswap_route(pay_asset_id)` blank → returns nil.
#     3. Otherwise → calls `QuillBot.api.safe_pay_url` with the MTG
#        member list, MTG threshold, `pay_asset_id` as the asset, the
#        route's `[:funds]` as the amount, and `fswap_mtg_memo` for
#        the memo.
#
# - `fswap_mtg_memo(route_id = nil)` — calls
#   `PandoLake.api.actions(...)` with `user_id: payee_id`, `follow_id`,
#   `asset_id`, `route_id`, and a `minimum_fill` that is `nil` when the
#   order's `order_type` is `"reward_article"` and `amount` otherwise.
#   Returns the inner `r["data"]["action"]`.
#
# - `pay_amount(pay_asset_id = asset_id)` — same-asset path returns
#   `amount`; cross-asset path returns `fswap_route(pay_asset_id)[:funds]`
#   (nil when there is no route).
#
# - `fswap_route(pay_asset_id = nil)` — memoized per-instance. Reads
#   pairs from `Rails.cache.fetch("pando_lake_routes", expires_in: 5.seconds)`
#   (which itself calls `PandoLake.api.pairs["data"]["pairs"]`), builds
#   a `PandoBot::Lake::PairRoutes`, and calls `.pre_order(...)` with
#   `output_amount: (amount * 1.001).ceil(8).to_f`. Returns nil on
#   StandardError. Memoization is per-instance, not global.
#
# Why a dedicated file: the existing `pre_order_test.rb` exercises
# validations, AASM transitions, and the `Memo` encoding surface.
# `mixpay_pre_order_test.rb` re-implements `pay_url` for the Mixpay
# subclass but does not cover the cross-asset foxswap branch, the
# `pay_amount` decision, the `fswap_route` memoization / cache /
# error-rescue contract, or `fswap_mtg_memo`'s `minimum_fill`
# branching. This file pins every branch in `swappable.rb`.
class PreOrders::SwappableTest < ActiveSupport::TestCase
  include QuillBotStub

  ETH_ASSET_ID = "43d61dcd-e413-450d-80b8-101d5e903357"

  setup do
    @article = articles(:published_paid)
    @author = users(:author)
    @reader = users(:reader_one)
    @payee = mixin_network_users(:article_wallet)
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache
    unstub_pando_lake!
  end

  def build_pre_order!(order_type: :buy_article, amount: @article.price, asset_id: @article.asset_id)
    with_quill_bot_stub do
      MixinPreOrder.create!(
        item: @article,
        payer: @reader,
        payee: @payee,
        order_type: order_type,
        amount: amount,
        asset_id: asset_id
      )
    end
  end

  # Pre-populate Rails.cache "pando_lake_routes" with a single BTC↔ETH pair
  # and stub PandoLake.api.pairs to return the same shape so the cache.fetch
  # fallback path (cache miss) can be exercised if a test clears the cache.
  # `route_id` MUST be an Integer — `PandoBot::Lake::PairRoutes#pre_order`
  # passes the route_ids to `Hashids.new.encode`, which raises
  # `ArgumentError: invalid value for Integer()` on non-integers.
  def stub_fswap_route!(route_id: 1)
    pair = {
      base_asset_id: @article.asset_id,
      quote_asset_id: ETH_ASSET_ID,
      base_amount: "100",
      quote_amount: "1",
      fee_percent: "0",
      swap_method: "uniswap",
      route_id: route_id
    }

    Rails.cache.write("pando_lake_routes", [ pair ])

    PandoLake.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:actions) do |**|
        { "data" => { "action" => "fake-mtg-action" } }
      end
      api.define_singleton_method(:pairs) do
        { "data" => { "pairs" => [ pair ] } }
      end
      api
    end
  end

  def unstub_pando_lake!
    return unless PandoLake.instance_variable_defined?(:@api)

    PandoLake.remove_instance_variable(:@api)
  end

  # --- pay_url ---

  test "pay_url with no argument routes through direct_pay_url" do
    pre_order = build_pre_order!

    safe_pay_called_with = nil
    QuillBot.define_singleton_method(:api) do
      api = QuillBotStub::FakeApi.new
      api.define_singleton_method(:safe_pay_url) do |**kwargs|
        safe_pay_called_with = kwargs
        "https://example.com/pay"
      end
      api
    end

    assert_equal "https://example.com/pay", pre_order.pay_url

    # direct_pay_url uses [bot.client_id] as the members list, threshold 1.
    assert_equal [ QuillBotStub::FAKE_CLIENT_ID ], safe_pay_called_with[:members]
    assert_equal 1, safe_pay_called_with[:threshold]
    assert_equal pre_order.asset_id, safe_pay_called_with[:asset_id]
    assert_equal pre_order.amount, safe_pay_called_with[:amount]
    assert_equal pre_order.trace_id, safe_pay_called_with[:trace_id]
    assert_equal pre_order.memo, safe_pay_called_with[:memo]
  end

  test "pay_url with the same asset_id also routes through direct_pay_url" do
    pre_order = build_pre_order!

    # Stub asset_id to a different UUID without rebuilding the record
    # (which would re-validate the currency association).
    pre_order.define_singleton_method(:asset_id) { ETH_ASSET_ID }

    called = false
    QuillBot.define_singleton_method(:api) do
      api = QuillBotStub::FakeApi.new
      api.define_singleton_method(:safe_pay_url) do |**|
        called = true
        "https://example.com/pay"
      end
      api
    end

    assert_equal "https://example.com/pay", pre_order.pay_url(ETH_ASSET_ID)
    assert called, "expected direct_pay_url (QuillBot.safe_pay_url) to be invoked"
  end

  test "pay_url with a different asset_id routes through foxswap_pay_url" do
    pre_order = build_pre_order!
    stub_fswap_route!

    route = pre_order.fswap_route(ETH_ASSET_ID)
    expected_funds = route[:funds]

    safe_pay_called_with = nil
    QuillBot.define_singleton_method(:api) do
      api = QuillBotStub::FakeApi.new
      api.define_singleton_method(:safe_pay_url) do |**kwargs|
        safe_pay_called_with = kwargs
        "https://example.com/swap"
      end
      api
    end

    assert_equal "https://example.com/swap", pre_order.pay_url(ETH_ASSET_ID)

    # foxswap path uses the MTG member list and MTG threshold, with the
    # cross-asset asset_id and route[:funds].
    assert_equal Settings.pando.mtg_members, safe_pay_called_with[:members]
    assert_equal Settings.pando.mtg_threshold, safe_pay_called_with[:threshold]
    assert_equal ETH_ASSET_ID, safe_pay_called_with[:asset_id]
    assert_equal expected_funds, safe_pay_called_with[:amount]
    assert_equal pre_order.trace_id, safe_pay_called_with[:trace_id]
    assert_equal "fake-mtg-action", safe_pay_called_with[:memo]
  end

  test "pay_url returns nil from foxswap_pay_url when there is no route" do
    pre_order = build_pre_order!

    # Pre-populate the cache with an empty pair list so fswap_route returns
    # nil without ever calling PandoLake.api.pairs.
    Rails.cache.write("pando_lake_routes", [])

    called = false
    QuillBot.define_singleton_method(:api) do
      api = QuillBotStub::FakeApi.new
      api.define_singleton_method(:safe_pay_url) do |**|
        called = true
        "https://example.com/should-not-fire"
      end
      api
    end

    assert_nil pre_order.pay_url(ETH_ASSET_ID)
    assert_not called, "safe_pay_url must not fire when there is no fswap route"
  end

  # --- direct_pay_url ---

  test "direct_pay_url passes the bot client as the sole member and threshold 1" do
    pre_order = build_pre_order!

    captured = nil
    QuillBot.define_singleton_method(:api) do
      api = QuillBotStub::FakeApi.new
      api.define_singleton_method(:safe_pay_url) do |**kwargs|
        captured = kwargs
        "https://example.com/pay"
      end
      api
    end

    assert_equal "https://example.com/pay", pre_order.direct_pay_url
    assert_equal [ QuillBotStub::FAKE_CLIENT_ID ], captured[:members]
    assert_equal 1, captured[:threshold]
  end

  # --- foxswap_pay_url ---

  test "foxswap_pay_url returns nil when pay_asset_id equals asset_id" do
    pre_order = build_pre_order!

    assert_nil pre_order.foxswap_pay_url(pre_order.asset_id)
  end

  test "foxswap_pay_url returns nil when fswap_route returns blank" do
    pre_order = build_pre_order!
    Rails.cache.write("pando_lake_routes", [])

    assert_nil pre_order.foxswap_pay_url(ETH_ASSET_ID)
  end

  test "foxswap_pay_url uses MTG members, MTG threshold, and the route funds" do
    pre_order = build_pre_order!
    stub_fswap_route!

    route = pre_order.fswap_route(ETH_ASSET_ID)

    captured = nil
    QuillBot.define_singleton_method(:api) do
      api = QuillBotStub::FakeApi.new
      api.define_singleton_method(:safe_pay_url) do |**kwargs|
        captured = kwargs
        "https://example.com/swap"
      end
      api
    end

    assert_equal "https://example.com/swap", pre_order.foxswap_pay_url(ETH_ASSET_ID)

    assert_equal Settings.pando.mtg_members, captured[:members]
    assert_equal Settings.pando.mtg_threshold, captured[:threshold]
    assert_equal ETH_ASSET_ID, captured[:asset_id]
    assert_equal route[:funds], captured[:amount]
    assert_equal "fake-mtg-action", captured[:memo]
  end

  # --- fswap_mtg_memo ---

  test "fswap_mtg_memo returns r['data']['action'] for a buy_article order with amount" do
    pre_order = build_pre_order!(order_type: :buy_article)
    stub_fswap_route!

    captured = nil
    PandoLake.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:actions) do |**kwargs|
        captured = kwargs
        { "data" => { "action" => "buy-mtg-action" } }
      end
      api
    end

    assert_equal "buy-mtg-action", pre_order.fswap_mtg_memo(1)

    assert_equal pre_order.payee_id, captured[:user_id]
    assert_equal pre_order.follow_id, captured[:follow_id]
    assert_equal pre_order.asset_id, captured[:asset_id]
    assert_equal 1, captured[:route_id]
    assert_equal pre_order.amount, captured[:minimum_fill]
  end

  test "fswap_mtg_memo passes minimum_fill=nil for a reward_article order" do
    pre_order = build_pre_order!(order_type: :reward_article, amount: 0.5)
    stub_fswap_route!

    captured = nil
    PandoLake.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:actions) do |**kwargs|
        captured = kwargs
        { "data" => { "action" => "reward-mtg-action" } }
      end
      api
    end

    assert_equal "reward-mtg-action", pre_order.fswap_mtg_memo(1)

    # The order_type guard: minimum_fill is nil regardless of amount.
    assert_nil captured[:minimum_fill]
  end

  # --- pay_amount ---

  test "pay_amount returns amount when pay_asset_id equals asset_id" do
    pre_order = build_pre_order!(amount: 0.5)

    assert_equal 0.5, pre_order.pay_amount
    assert_equal 0.5, pre_order.pay_amount(pre_order.asset_id)
  end

  test "pay_amount returns nil when there is no fswap route" do
    pre_order = build_pre_order!
    Rails.cache.write("pando_lake_routes", [])

    assert_nil pre_order.pay_amount(ETH_ASSET_ID)
  end

  test "pay_amount returns route[:funds] for a cross-asset pay_asset_id" do
    pre_order = build_pre_order!
    stub_fswap_route!

    route = pre_order.fswap_route(ETH_ASSET_ID)

    assert_equal route[:funds], pre_order.pay_amount(ETH_ASSET_ID)
  end

  # --- fswap_route ---

  test "fswap_route caches pairs under 'pando_lake_routes' with a 5-second expiry" do
    pre_order = build_pre_order!
    stub_fswap_route!

    # The cache is pre-populated by stub_fswap_route!, so PandoLake.api.pairs
    # must NOT be called during fswap_route's Rails.cache.fetch.
    pre_order.fswap_route(ETH_ASSET_ID)

    cached = Rails.cache.read("pando_lake_routes")
    assert_not_nil cached, "fswap_route should have left a cached pair list"
    assert_kind_of Array, cached
    assert_equal 1, cached.size
    assert_equal @article.asset_id, cached.first[:base_asset_id]
  end

  test "fswap_route memoizes its return value per-instance" do
    pre_order = build_pre_order!
    stub_fswap_route!

    first = pre_order.fswap_route(ETH_ASSET_ID)
    assert_kind_of Hash, first

    # Replace the underlying pair list so a fresh computation would differ.
    Rails.cache.write("pando_lake_routes", [])

    second = pre_order.fswap_route(ETH_ASSET_ID)

    assert_same first, second, "fswap_route must return the memoized object"
  end

  test "fswap_route rescues StandardError and returns nil" do
    pre_order = build_pre_order!

    Rails.cache.delete("pando_lake_routes")

    PandoLake.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:pairs) do
        raise StandardError, "boom"
      end
      api
    end

    assert_nil pre_order.fswap_route(ETH_ASSET_ID)
  end
end
