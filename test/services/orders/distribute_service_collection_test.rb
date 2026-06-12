# frozen_string_literal: true

require "test_helper"

class Orders::DistributeServiceCollectionTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @reader_one = users(:reader_one)
    @reader_two = users(:reader_two)
    @collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Distribute Test Collection",
      symbol: "DTC",
      description: "A collection for distribution tests",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.2,
      platform_revenue_ratio: 0.1,
      state: "listed"
    )
  end

  test "buy_collection creates quill_revenue and author_revenue only" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order
      assert_equal :buy_collection, order.order_type.to_sym

      distribute_order!(order)

      types = order.transfers.pluck(:transfer_type).map(&:to_s).tally
      assert_equal 1, types["quill_revenue"], "Exactly one quill_revenue transfer expected"
      assert_equal 1, types["author_revenue"], "Exactly one author_revenue transfer expected"
      assert_nil types["reader_revenue"], "buy_collection should not create reader_revenue"
      assert_nil types["reference_revenue"], "buy_collection should not create reference_revenue"
    end
  end

  test "buy_collection author_revenue amount equals total minus quill_amount" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order
      total = order.total.to_f
      # collection.platform_revenue_ratio defaults to 0.1; quill_amount = total * 0.1
      expected_quill = (total * @collection.platform_revenue_ratio).floor(8)
      expected_author = (total - expected_quill).floor(8)

      distribute_order!(order)

      quill_transfer = order.transfers.find_by(transfer_type: :quill_revenue)
      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)

      assert quill_transfer, "quill_revenue transfer should exist"
      assert author_transfer, "author_revenue transfer should exist"
      assert_in_delta expected_quill, quill_transfer.amount.to_f, 0.000_000_01
      assert_in_delta expected_author, author_transfer.amount.to_f, 0.000_000_01
    end
  end

  test "buy_collection author_revenue memo is \"{buyer_name} bought {item_name}\"" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      expected_memo = "#{@reader_one.name} bought #{@collection.name}".truncate(70)
      assert_equal expected_memo, author_transfer.memo
    end
  end

  test "buy_collection author_revenue memo is truncated to 70 characters for long names" do
    long_name = "X" * 100
    long_collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: long_name,
      symbol: "LNG",
      description: "Long-named collection",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.2,
      platform_revenue_ratio: 0.1,
      state: "listed"
    )

    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: long_collection,
        order_type: "BUY",
        amount: long_collection.price
      )
      order = payment.order

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert author_transfer, "author_revenue transfer should exist"
      assert_operator author_transfer.memo.length, :<=, 70,
                      "Memo should be truncated to 70 chars"
      # The full memo "Reader One bought XXX...XXX" would exceed 70, so it must be truncated.
      full_memo = "#{@reader_one.name} bought #{long_name}"
      assert_operator full_memo.length, :>, 70, "Sanity: full memo should exceed 70 chars"
      assert_equal full_memo.truncate(70), author_transfer.memo
    end
  end

  test "buy_collection author_revenue opponent_id is the collection author's mixin_uuid" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert_equal @author.mixin_uuid, author_transfer.opponent_id
    end
  end

  test "buy_collection quill_revenue opponent_id is the QuillBot client_id" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      distribute_order!(order)

      quill_transfer = order.transfers.find_by(transfer_type: :quill_revenue)
      assert quill_transfer, "quill_revenue transfer should exist"
      assert_equal QuillBot.api.client_id, quill_transfer.opponent_id
    end
  end

  test "buy_collection quill_revenue is skipped when payment wallet equals bot client_id" do
    # Snapshot whose user_id matches QuillBot.api.client_id. The service checks
    # `payment.wallet_id != QuillBot.api.client_id` before creating quill_revenue,
    # so this scenario must NOT produce a quill_revenue transfer.
    bot_client_id = QuillBotStub::FAKE_CLIENT_ID

    with_quill_bot_stub(client_id: bot_client_id) do
      snapshot = MixinNetworkSnapshot.create!(
        snapshot_id: SecureRandom.uuid,
        user_id: bot_client_id,
        asset_id: Currency::BTC_ASSET_ID,
        amount: 0,
        trace_id: SecureRandom.uuid,
        opponent_id: @reader_one.mixin_uuid,
        transferred_at: Time.current,
        data: ""
      )

      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      # Re-bind the payment's snapshot to the bot's wallet.
      payment.update_columns(snapshot_id: snapshot.snapshot_id, trace_id: snapshot.trace_id)
      order = payment.order
      order.update_columns(trace_id: snapshot.trace_id)

      distribute_order!(order)

      assert_nil order.transfers.find_by(transfer_type: :quill_revenue),
                 "quill_revenue should be skipped when wallet matches bot client_id"
      # Author revenue is still created unconditionally.
      assert order.transfers.find_by(transfer_type: :author_revenue),
             "author_revenue should still be created"
    end
  end

  test "buy_collection distribution is idempotent" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order
      distribute_order!(order)
      first_count = order.transfers.count

      distribute_order!(order)

      assert_equal first_count, order.transfers.count,
                   "Re-distributing buy_collection should not create new transfers"
    end
  end

  test "buy_collection distribution is skipped when order is already completed" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order
      # Bypass the AASM guard; we're testing the distribute! short-circuit.
      order.update_column(:state, "completed")
      initial_count = order.transfers.count

      distribute_order!(order)

      assert_equal initial_count, order.transfers.count,
                   "No new transfers for already-completed collection order"
    end
  end

  test "buy_collection transfers carry queue_priority low" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      distribute_order!(order)

      order.transfers.each do |t|
        assert_equal "low", t.queue_priority.to_s,
                     "All collection-order transfers should be queued at low priority"
      end
    end
  end

  test "buy_collection trace_id for author_revenue is deterministic and matches unique_uuid" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order
      expected_trace_id = MixinBot::Utils.unique_uuid(order.trace_id, @author.mixin_uuid)

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert_equal expected_trace_id, author_transfer.trace_id,
                   "author_revenue trace_id must be derived from order.trace_id + author.mixin_uuid"
    end
  end

  test "buy_collection author_revenue asset_id matches payment asset_id" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      quill_transfer = order.transfers.find_by(transfer_type: :quill_revenue)
      # For buy_collection with no swap, revenue_asset_id = payment.asset_id.
      assert_equal payment.asset_id, author_transfer.asset_id
      assert_equal payment.asset_id, quill_transfer.asset_id
    end
  end

  test "buy_collection uses swap_order fill_asset_id when present" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      # Build a swap_order stub that exposes only fill_asset_id, mimicking the
      # shape used by distribute_service. The order's payment.swap_order must
      # respond to fill_asset_id.
      fill_asset = "99999999-9999-4999-8999-999999999999"
      swap_order_stub = Struct.new(:fill_asset_id).new(fill_asset)
      payment.define_singleton_method(:swap_order) { swap_order_stub }

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      quill_transfer = order.transfers.find_by(transfer_type: :quill_revenue)
      assert_equal fill_asset, author_transfer.asset_id,
                   "author_revenue should use swap_order.fill_asset_id when swap_order is present"
      assert_equal fill_asset, quill_transfer.asset_id
    end
  end

  test "buy_collection second buy of same collection produces independent transfers" do
    with_quill_bot_stub do
      first = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      distribute_order!(first.order)
      first_count = first.order.transfers.count

      second = create_payment!(
        payer: @reader_two,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      distribute_order!(second.order)

      # Each order has its own transfers association; second buyer has its own set.
      assert_equal first_count, second.order.transfers.count,
                   "Second buy should produce the same transfer count as first"
      assert_not_equal first.order.transfers.first.trace_id,
                      second.order.transfers.first.trace_id,
                      "Distinct orders should produce distinct trace_ids"
    end
  end

  test "buy_collection transfer amounts satisfy all_transfers_generated? (non-bot wallet)" do
    # When the payment wallet is not the bot's, all_transfers_generated? sums to total.
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        collection: @collection,
        order_type: "BUY",
        amount: @collection.price
      )
      order = payment.order

      distribute_order!(order)

      assert order.all_transfers_generated?,
             "buy_collection transfers should sum to total when wallet != bot"
    end
  end
end
