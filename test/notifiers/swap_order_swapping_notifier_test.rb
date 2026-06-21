# frozen_string_literal: true

require "test_helper"

class SwapOrderSwappingNotifierTest < ActiveSupport::TestCase
  setup do
    @payer = users(:reader_one)
    ensure_notification_setting!(@payer)
    @pay_asset = currencies(:btc)
    @fill_asset = create_currency!(symbol: "USDT", price_btc: 0.0001, price_usd: 1.0)
    @payment = create_payment_for!(payer: @payer, asset_id: @pay_asset.asset_id)
    @swap_order = build_swap_order!(
      payer: @payer,
      pay_asset: @pay_asset,
      fill_asset: @fill_asset,
      payment: @payment
    )
  end

  test "deliver creates noticed event and notification records" do
    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(
          SwapOrderSwappingNotifier,
          record: @swap_order,
          swap_order: @swap_order,
          recipient: @payer
        )
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@payer)

    assert_equal "SwapOrderSwappingNotifier", event.type
    assert_equal @swap_order, event.record
    assert_equal @swap_order, notification.params[:swap_order]
    assert notification.visible_in_web?
  end

  test "message includes the swapping translation" do
    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_includes notification.message,
                    I18n.t("notifiers.swap_order_swapping_notifier.notification.swapping")
  end

  test "message joins the swapping translation, pay asset symbol, arrow, and fill asset symbol with spaces" do
    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_equal [
      I18n.t("notifiers.swap_order_swapping_notifier.notification.swapping"),
      @pay_asset.symbol,
      "->",
      @fill_asset.symbol
    ].join(" "), notification.message
  end

  test "url anchors to the dashboard orders page" do
    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_includes notification.url, "/dashboard/orders"
  end

  test "data equals message (PLAIN_TEXT shape)" do
    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    notification = notification_for(@payer)

    assert_equal notification.message, notification.data
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @payer.messenger?

    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "may_notify_via_mixin_bot is true for messenger recipients by default" do
    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    assert notification_for(@payer).may_notify_via_mixin_bot?
  end

  test "may_notify_via_mixin_bot is false when recipient is not a messenger" do
    user_authorizations(:reader_one_auth).update!(provider: "fennec")

    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    assert_not notification_for(@payer).may_notify_via_mixin_bot?
  end

  test "does not enqueue a mixin bot message when recipient is not a messenger" do
    user_authorizations(:reader_one_auth).update!(provider: "fennec")

    deliver_notifier!(
      SwapOrderSwappingNotifier,
      record: @swap_order,
      swap_order: @swap_order,
      recipient: @payer
    )

    perform_enqueued_jobs only: Noticed::EventJob
    perform_enqueued_jobs only: DeliveryMethods::MixinBot

    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end

  private

  def create_currency!(symbol:, price_btc:, price_usd:)
    asset_id = SecureRandom.uuid
    raw = {
      "symbol" => symbol,
      "name" => symbol,
      "icon_url" => "https://example.com/#{symbol.downcase}.png",
      "asset_id" => asset_id,
      "chain_id" => SecureRandom.uuid,
      "price_btc" => price_btc.to_s,
      "price_usd" => price_usd.to_s
    }

    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:asset) { |_id| { "data" => raw } }
      Currency.create!(
        asset_id: asset_id,
        symbol: symbol,
        price_btc: price_btc,
        price_usd: price_usd,
        raw: raw
      )
    end
  end

  def build_swap_order!(payer:, pay_asset:, fill_asset:, payment:)
    swap = SwapOrder.new(
      user_id: payer.mixin_uuid,
      payment: payment,
      pay_asset_id: pay_asset.asset_id,
      fill_asset_id: fill_asset.asset_id,
      funds: 0.001,
      amount: 50.0,
      state: "swapping",
      trace_id: SecureRandom.uuid
    )

    had_api = false
    original_api = nil

    # Stub PandoLake to avoid the after_create call to fswap_mtg_memo.
    stub_api = Object.new
    stub_api.define_singleton_method(:actions) { |**| { "data" => { "action" => "test_memo" } } }

    had_api = PandoLake.instance_variable_defined?(:@api)
    original_api = PandoLake.instance_variable_get(:@api) if had_api
    PandoLake.instance_variable_set(:@api, stub_api)

    swap.save!
    swap
  ensure
    if had_api
      PandoLake.instance_variable_set(:@api, original_api)
    elsif PandoLake.instance_variable_defined?(:@api)
      PandoLake.remove_instance_variable(:@api)
    end
  end

  def create_payment_for!(payer:, asset_id:)
    trace_id = SecureRandom.uuid
    snapshot_id = SecureRandom.uuid

    raw = {
      "amount" => "0.001",
      "asset_id" => asset_id,
      "memo" => Base64.encode64({ "t" => "BUY" }.to_json),
      "opponent_id" => payer.mixin_uuid,
      "snapshot_id" => snapshot_id,
      "trace_id" => trace_id,
      "data" => Base64.encode64({ "t" => "BUY" }.to_json)
    }

    stub_notifications! do
      with_quill_bot_stub do
        Payment.create!(
          amount: 0.001,
          raw: raw,
          asset_id: asset_id,
          snapshot_id: snapshot_id,
          trace_id: trace_id,
          payer: payer,
          state: "completed"
        )
      end
    end
  end
end
