# frozen_string_literal: true

require "test_helper"

class Admin::WalletsControllerTest < ActionController::TestCase
  tests Admin::WalletsController

  BTC_ASSET_ID = "c6d0c728-2624-429b-8e0d-d9d19b6592fa"

  setup do
    @request.session[:current_admin_id] = administrators(:one).id
  end

  test "assets resolves the platform wallet by client_id and renders its assets" do
    with_quill_bot_stub do
      rows = [ platform_asset_row ]
      QuillBot.api.define_singleton_method(:assets) { { "data" => rows } }

      get :assets, params: { wallet_id: QuillBotStub::FAKE_CLIENT_ID }

      assert_response :success
      assert_equal 1, @controller.instance_variable_get(:@assets).size
      assert_equal QuillBotStub::FAKE_CLIENT_ID, @controller.instance_variable_get(:@wallet).client_id
    end
  end

  test "snapshots resolves a mixin network user wallet with a single lookup and paginates a full page" do
    wallet = mixin_network_users(:article_wallet)

    with_quill_bot_stub do
      with_user_wallet_api(snapshots: Array.new(25) { snapshot_row }) do
        # load_wallet used to run the lookup twice per request: once for the
        # truthiness check, then again for the value. Both calls run through
        # the statement cache, whose events assert_queries_match skips as
        # cached — so the SQL stream is captured directly.
        queries = capture_wallet_queries do
          ActiveRecord::Base.lease_connection.uncached do
            get :snapshots, params: { wallet_id: wallet.uuid }
          end
        end
        assert_equal 1, queries.size, "expected one wallet lookup, got:\n#{queries.join("\n")}"

        assert_response :success
        assert_equal 25, @controller.instance_variable_get(:@snapshots).size
        assert @controller.instance_variable_get(:@has_next)
      end
    end
  end

  test "snapshots marks a short page as the last one" do
    wallet = mixin_network_users(:article_wallet)

    with_quill_bot_stub do
      with_user_wallet_api(snapshots: [ snapshot_row ]) do
        get :snapshots, params: { wallet_id: wallet.uuid }

        assert_response :success
        assert_equal 1, @controller.instance_variable_get(:@snapshots).size
        refute @controller.instance_variable_get(:@has_next)
      end
    end
  end

  test "safe_outputs requests unspent outputs and paginates a full page" do
    wallet = mixin_network_users(:article_wallet)
    requested_args = nil

    with_quill_bot_stub do
      rows = Array.new(100) { safe_output_row }
      with_user_wallet_api do |api|
        api.define_singleton_method(:safe_outputs) do |**args|
          requested_args = args
          { "data" => rows }
        end

        get :safe_outputs, params: { wallet_id: wallet.uuid }
      end
    end

    assert_response :success
    assert_equal({ limit: 100, state: :unspent, offset: nil }, requested_args)
    assert @controller.instance_variable_get(:@has_next)
  end

  test "an unknown wallet_id raises Wallet not found" do
    with_quill_bot_stub do
      error = assert_raises(RuntimeError) { get :assets, params: { wallet_id: "not-a-wallet" } }

      assert_equal "Wallet not found", error.message
    end
  end

  private

  def capture_wallet_queries
    queries = []
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
      sql = event.payload[:sql]
      queries << sql if sql&.match?(/mixin_network_users/i)
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  # The controller resolves `MixinNetworkUser#mixin_api` on a record it loads
  # itself, so the stub has to live on the class for the duration of the
  # request — the same reason mixin_network_user_test stubs per instance.
  def with_user_wallet_api(snapshots: [], safe_outputs: [])
    fake = Object.new
    fake.define_singleton_method(:assets) { { "data" => [] } }
    fake.define_singleton_method(:snapshots) { |limit:, offset:| { "data" => snapshots } }
    fake.define_singleton_method(:safe_outputs) { |**args| { "data" => safe_outputs } }

    MixinNetworkUser.alias_method :__test_original_mixin_api, :mixin_api
    MixinNetworkUser.define_method(:mixin_api) { fake }
    yield fake
  ensure
    MixinNetworkUser.alias_method :mixin_api, :__test_original_mixin_api
    MixinNetworkUser.remove_method :__test_original_mixin_api
  end

  def platform_asset_row
    {
      "icon_url" => "https://example.com/btc.png",
      "symbol" => "BTC",
      "asset_id" => BTC_ASSET_ID,
      "balance" => "1",
      "price_usd" => "50000"
    }
  end

  def snapshot_row
    {
      "type" => "transfer",
      "asset_id" => BTC_ASSET_ID,
      "amount" => "1",
      "opponent_id" => "opponent-1",
      "memo" => "memo",
      "created_at" => "2026-11-01T00:00:00Z",
      "snapshot_id" => "snap-1",
      "trace_id" => "trace-1"
    }
  end

  def safe_output_row
    {
      "type" => "output",
      "asset_id" => BTC_ASSET_ID,
      "amount" => "1",
      "state" => "unspent",
      "extra" => "00",
      "created_at" => "2026-11-01T00:00:00Z",
      "sequence" => 1,
      "request_id" => "req-1"
    }
  end
end
