# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
# Database name: primary
#
#  id         :bigint           not null, primary key
#  citer_type :string
#  item_type  :string
#  order_type :integer
#  state      :string
#  total      :decimal(, )
#  value_btc  :decimal(, )
#  value_usd  :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  buyer_id   :bigint
#  citer_id   :integer
#  item_id    :bigint
#  seller_id  :bigint
#  trace_id   :uuid
#
# Indexes
#
#  index_orders_on_asset_id                 (asset_id)
#  index_orders_on_buyer_id                 (buyer_id)
#  index_orders_on_citer_type_and_citer_id  (citer_type,citer_id)
#  index_orders_on_item_type_and_item_id    (item_type,item_id)
#  index_orders_on_seller_id                (seller_id)
#
require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @author = users(:author)
    @reader_one = users(:reader_one)
    @reader_two = users(:reader_two)
  end

  test "first buy creates platform and author transfers only" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      types = order.transfers.pluck(:transfer_type).map(&:to_s)
      assert_includes types, "quill_revenue"
      assert_includes types, "author_revenue"
      assert_not_includes types, "reader_revenue"
    end
  end

  test "second buy distributes reader revenue proportionally" do
    with_quill_bot_stub do
      create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 3.days.ago
      )
      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )
      distribute_order!(order)

      reader_transfers = order.transfers.where(transfer_type: :reader_revenue)
      assert reader_transfers.exists?
      assert reader_transfers.where(opponent_id: @reader_one.mixin_uuid).exists?
    end
  end

  test "distribute! is idempotent" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)
      count_after_first = order.transfers.count

      distribute_order!(order)

      assert_equal count_after_first, order.transfers.count
    end
  end

  test "reward_article orders count as early readers" do
    with_quill_bot_stub do
      payment = create_payment!(payer: @reader_one, article: @article, order_type: "REWARD", amount: 0.5)
      reward_order = payment.order
      reward_order.update_columns(created_at: 3.days.ago, updated_at: 3.days.ago)

      buy_order = create_buy_order!(article: @article, buyer: @reader_two, total: 1.0)
      assert_includes buy_order.early_orders.pluck(:id), reward_order.id
    end
  end

  test "all_transfers_generated? when transfers sum to expected amount" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      assert order.all_transfers_generated?
    end
  end

  test "article with reference distributes reference revenue" do
    with_quill_bot_stub do
      referenced_article = articles(:published_free)
      CiterReference.create!(
        citer: @article,
        reference: referenced_article,
        revenue_ratio: 0.05
      )

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      reference_transfer = order.transfers.find_by(transfer_type: :reference_revenue)
      assert reference_transfer, "Reference revenue transfer should exist"
      assert_in_delta 0.05, reference_transfer.amount.to_f, 0.001
    end
  end

  test "article with multiple references distributes revenue proportionally" do
    with_quill_bot_stub do
      ref1 = articles(:published_free)
      ref2 = articles(:high_revenue)

      CiterReference.create!(citer: @article, reference: ref1, revenue_ratio: 0.03)
      CiterReference.create!(citer: @article, reference: ref2, revenue_ratio: 0.02)

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      transfers = order.transfers.where(transfer_type: :reference_revenue)
      assert_equal 2, transfers.count

      amounts = transfers.pluck(:amount).map(&:to_f)
      assert_in_delta 0.05, amounts.sum, 0.001
    end
  end

  test "reference revenue skipped when amount is below minimum" do
    with_quill_bot_stub do
      tiny_ratio_article = articles(:published_free)
      # Ratio small enough that total * ratio floors below MINIMUM_AMOUNT
      CiterReference.create!(
        citer: @article,
        reference: tiny_ratio_article,
        revenue_ratio: 0.0000_00001
      )

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      reference_transfer = order.transfers.find_by(transfer_type: :reference_revenue)
      assert_nil reference_transfer
    end
  end

  test "author revenue is reduced by reference and collection amounts" do
    with_quill_bot_stub do
      referenced_article = articles(:published_free)
      CiterReference.create!(
        citer: @article,
        reference: referenced_article,
        revenue_ratio: 0.10
      )

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert author_transfer, "Author revenue transfer should exist"

      # Author revenue should be: total - quill - readers - references
      # 1.0 - 0.1 (quill) - 0 (first buyer, no early readers) - 0.10 (reference) = 0.80
      assert_in_delta 0.80, author_transfer.amount.to_f, 0.001
    end
  end

  test "distribution is idempotent with references" do
    with_quill_bot_stub do
      referenced_article = articles(:published_free)
      CiterReference.create!(
        citer: @article,
        reference: referenced_article,
        revenue_ratio: 0.05
      )

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)
      first_count = order.transfers.count

      distribute_order!(order)
      second_count = order.transfers.count

      assert_equal first_count, second_count, "Distribution should be idempotent"
    end
  end

  # === Collection revenue distribution ===

  test "article in collection distributes collection revenue to subscribers" do
    with_quill_bot_stub do
      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "Test Collection",
        symbol: "TC",
        description: "A collection for testing",
        author: @author,
        asset_id: @article.asset_id,
        price: 0.001,
        revenue_ratio: 0.1,
        state: "listed"
      )
      collection.update_column(:uuid, SecureRandom.uuid)

      # Bypass validations on the already-published article — these tests only
      # need the article to be in the right state for distribution logic.
      @article.update_columns(
        collection_id: collection.uuid,
        collection_revenue_ratio: collection.revenue_ratio
      )
      @article.reload

      # Create a collection subscriber (use create_payment! so the Payment's
      # after_create :generate_order! callback creates the buy_collection
      # order through the proper polymorphic association).
      create_payment!(payer: @reader_one, collection: collection, order_type: "BUY", amount: collection.price)

      order = create_buy_order!(article: @article, buyer: @reader_two, total: 1.0)
      distribute_order!(order)

      # The only reader_revenue transfer should be the collection revenue to the subscriber
      collection_revenue_transfer = order.transfers.find_by(
        transfer_type: :reader_revenue,
        opponent_id: @reader_one.mixin_uuid
      )
      assert collection_revenue_transfer, "Collection revenue transfer should exist for subscriber"
      # _collection_sum = 1.0 * 0.1 = 0.1; _collection_avg = 0.1 / 1 = 0.1
      assert_in_delta 0.1, collection_revenue_transfer.amount.to_f, 0.001
    end
  end

  test "collection revenue skipped when avg amount at or below minimum" do
    with_quill_bot_stub do
      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "Tiny Revenue Collection",
        symbol: "TRC",
        description: "Collection whose per-subscriber avg falls below MINIMUM_AMOUNT",
        author: @author,
        asset_id: @article.asset_id,
        price: 0.001,
        revenue_ratio: 0.1,
        state: "listed"
      )
      collection.update_column(:uuid, SecureRandom.uuid)

      # Pick collection_revenue_ratio so that _collection_avg_amount == MINIMUM_AMOUNT.
      # _collection_avg = (total * collection_revenue_ratio) / subscribers
      # For total=1.0 and 1 subscriber, ratio=MINIMUM_AMOUNT yields avg == MINIMUM_AMOUNT,
      # which fails the `.positive?` guard and skips the transfer.
      @article.update_columns(
        collection_id: collection.uuid,
        collection_revenue_ratio: Orders::DistributeService::MINIMUM_AMOUNT
      )
      @article.reload

      create_payment!(payer: @reader_one, collection: collection, order_type: "BUY", amount: collection.price)

      order = create_buy_order!(article: @article, buyer: @reader_two, total: 1.0)
      distribute_order!(order)

      reader_transfers = order.transfers.where(transfer_type: :reader_revenue)
      assert_empty reader_transfers, "No reader revenue when collection avg at or below minimum"
    end
  end

  test "collection revenue skipped when article has no collection" do
    with_quill_bot_stub do
      # Bypass validations on the already-published article
      @article.update_columns(collection_id: nil, collection_revenue_ratio: 0.0)
      @article.reload

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      reader_transfers = order.transfers.where(transfer_type: :reader_revenue)
      assert_empty reader_transfers, "No reader revenue when article has no collection"
    end
  end

  # === Currency mixing in early reader detection ===

  test "same currency early readers use total for proportion calculation" do
    with_quill_bot_stub do
      create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 3.days.ago
      )

      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )
      distribute_order!(order)

      reader_transfer = order.transfers.find_by(transfer_type: :reader_revenue, opponent_id: @reader_one.mixin_uuid)
      assert reader_transfer, "Reader revenue transfer should exist for early reader"
      # Same-currency path: amount = total * readers_revenue_ratio * share / sum
      # = 2.0 * 0.4 * 1.0 / 1.0 = 0.8
      assert_in_delta 0.8, reader_transfer.amount.to_f, 0.01
    end
  end

  test "different currency early readers use value_btc for proportion" do
    with_quill_bot_stub do
      early_order = create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 3.days.ago
      )
      # Trigger the value_btc branch: early order's asset_id must differ from
      # the current order's. value_btc is then used as the share denominator.
      early_order.update_columns(
        asset_id: "11111111-1111-4111-8111-111111111111",
        value_btc: 0.5
      )

      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )
      distribute_order!(order)

      # Different-currency path: amount = total * readers_revenue_ratio * share / sum
      # where share/sum are value_btc. With share == sum (single early order),
      # the amount still equals 0.8, but the calculation must take the value_btc branch.
      reader_transfer = order.transfers.find_by(transfer_type: :reader_revenue, opponent_id: @reader_one.mixin_uuid)
      assert reader_transfer, "Reader revenue should be distributed using value_btc when asset_id differs"
    end
  end

  # === Service idempotency and edge cases ===

  test "distribute! skips already completed orders" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      # Bypass the AASM guard so we can mark the order completed without
      # having to first generate all the transfers the guard would check for.
      order.update_column(:state, "completed")
      initial_count = order.transfers.count

      distribute_order!(order)

      assert_equal initial_count, order.transfers.count, "No new transfers for completed order"
    end
  end

  test "author revenue accounts for collection revenue share" do
    with_quill_bot_stub do
      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "Revenue Collection",
        symbol: "RC",
        description: "Collection for testing revenue",
        author: @author,
        asset_id: @article.asset_id,
        price: 0.001,
        revenue_ratio: 0.1,
        state: "listed"
      )
      collection.update_column(:uuid, SecureRandom.uuid)

      @article.update_columns(
        collection_id: collection.uuid,
        collection_revenue_ratio: 0.1
      )
      @article.reload

      create_payment!(payer: @reader_one, collection: collection, order_type: "BUY", amount: collection.price)

      order = create_buy_order!(article: @article, buyer: @reader_two, total: 1.0)
      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      collection_reader_transfer = order.transfers.find_by(transfer_type: :reader_revenue, opponent_id: @reader_one.mixin_uuid)

      # Total = 1.0, quill = 0.1, no early readers, collection avg = 0.1
      # Author = 1.0 - 0 - 0.1 - 0 - 0.1 = 0.8
      author_amount = author_transfer&.amount&.to_f || 0
      assert_in_delta 0.8, author_amount, 0.01, "Author revenue should account for collection share"
      assert collection_reader_transfer, "Collection subscriber should receive reader_revenue transfer"
    end
  end

  # === Early reader detection: same reader, multiple orders ===

  test "same reader with two same-currency orders gets a single combined share" do
    with_quill_bot_stub do
      # Same reader rewarded once and bought once. Both qualify as
      # "early" (buy_article + reward_article are both in early_orders).
      # collect_early_readers should fold both trace_ids into one entry,
      # so only one reader_revenue transfer is created for that buyer.
      reward_payment = create_payment!(payer: @reader_one, article: @article, order_type: "REWARD", amount: 1.0)
      reward_order = reward_payment.order
      reward_order.update_columns(created_at: 4.days.ago, updated_at: 4.days.ago)

      create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 2.days.ago
      )

      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )

      # Sanity check the early reader grouping
      readers = order.collect_early_readers
      assert_equal 1, readers.keys.size, "Two same-reader orders should fold into one group"
      assert_equal 2, readers[@reader_one.mixin_uuid].size, "Both trace_ids should be present"

      distribute_order!(order)

      reader_transfers = order.transfers.where(transfer_type: :reader_revenue, opponent_id: @reader_one.mixin_uuid)
      assert_equal 1, reader_transfers.count, "Same reader should receive exactly one reader_revenue transfer"

      # Same-currency: amount = total * readers_revenue_ratio * share / sum
      # share = sum of reader_one's totals = 2.0; sum = total of all early orders = 2.0
      # amount = 2.0 * 0.4 * 2.0 / 2.0 = 0.8
      assert_in_delta 0.8, reader_transfers.first.amount.to_f, 0.01
    end
  end

  test "same reader with two mixed-currency orders forces value_btc path" do
    with_quill_bot_stub do
      # Two early orders from the same reader, one in a different asset.
      # The buyer-mixed-currency case forces the value_btc branch via
      # early_orders_with_the_same_currency.
      reward_payment = create_payment!(payer: @reader_one, article: @article, order_type: "REWARD", amount: 1.0)
      reward_order = reward_payment.order
      reward_order.update_columns(
        created_at: 4.days.ago,
        updated_at: 4.days.ago,
        asset_id: "11111111-1111-4111-8111-111111111111"
      )

      create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 2.days.ago
      )

      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )

      # Sanity: the same-reader grouping is preserved across currencies.
      readers = order.collect_early_readers
      assert_equal 1, readers.keys.size
      assert_equal 2, readers[@reader_one.mixin_uuid].size

      # Both early orders are in the reader_revenue grouping regardless of currency.
      refute order.send(:early_orders_with_the_same_currency),
             "Different-currency early orders should disable the same-currency shortcut"

      distribute_order!(order)

      reader_transfers = order.transfers.where(transfer_type: :reader_revenue, opponent_id: @reader_one.mixin_uuid)
      assert reader_transfers.exists?, "Reader revenue transfer should exist even with mixed-currency early orders"
      # Reader revenue should be non-negative and the share should be non-zero.
      assert reader_transfers.first.amount.to_f.positive?,
             "Same reader across two currencies should still receive reader revenue"
    end
  end

  test "reward and buy from same reader fold into one group" do
    with_quill_bot_stub do
      # Reader first rewarded, then bought. Both qualify as "early" (buy_article + reward_article).
      # They should fold into a single collect_early_readers entry.
      reward_payment = create_payment!(payer: @reader_one, article: @article, order_type: "REWARD", amount: 0.5)
      reward_order = reward_payment.order
      reward_order.update_columns(created_at: 4.days.ago, updated_at: 4.days.ago)

      create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 2.days.ago
      )

      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 1.0,
        created_at: 1.day.ago
      )

      readers = order.collect_early_readers
      assert_equal 1, readers.keys.size, "Reward + buy from same reader should fold into one group"
      assert_equal 2, readers[@reader_one.mixin_uuid].size
      assert_includes readers[@reader_one.mixin_uuid], reward_order.trace_id
    end
  end

  test "multiple early readers with mixed currencies use value_btc share" do
    with_quill_bot_stub do
      # Two early readers, each with their own currency. Verifies the
      # value_btc path works for the multi-reader share calculation.
      create_buy_order!(
        article: @article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 4.days.ago
      )
      # Use a third reader fixture for the second early order so both can be
      # independent currencies, and so they don't fold into one group.
      blocked_reader = users(:blocked_reader)
      second_early = create_buy_order!(
        article: @article,
        buyer: blocked_reader,
        total: 1.0,
        created_at: 2.days.ago
      )
      # Flip one to a different asset to force the value_btc branch.
      second_early.update_columns(asset_id: "11111111-1111-4111-8111-111111111111")

      order = create_buy_order!(
        article: @article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )

      refute order.send(:early_orders_with_the_same_currency),
             "Mixed-currency early orders should disable the same-currency shortcut"

      distribute_order!(order)

      # Both early readers should still receive reader revenue.
      reader_one_transfer = order.transfers.find_by(transfer_type: :reader_revenue, opponent_id: @reader_one.mixin_uuid)
      blocked_transfer = order.transfers.find_by(transfer_type: :reader_revenue, opponent_id: blocked_reader.mixin_uuid)
      assert reader_one_transfer, "Same-currency early reader should still receive reader revenue"
      assert blocked_transfer, "Different-currency early reader should still receive reader revenue"
      assert reader_one_transfer.amount.to_f.positive?
      assert blocked_transfer.amount.to_f.positive?
    end
  end

  test "collect_early_readers returns empty hash when no prior orders" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)

      assert_equal({}, order.collect_early_readers)
    end
  end
end
