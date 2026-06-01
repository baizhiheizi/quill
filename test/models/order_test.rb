# frozen_string_literal: true

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
      assert_in_delta 0.03, amounts.sum, 0.001
    end
  end

  test "reference revenue skipped when amount is below minimum" do
    with_quill_bot_stub do
      tiny_ratio_article = articles(:published_free)
      # Create a reference with a very small revenue ratio
      CiterReference.create!(
        citer: @article,
        reference: tiny_ratio_article,
        revenue_ratio: 0.0000_0001
      )

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 0.0000_0001)
      distribute_order!(order)

      # Amount would be below MINIMUM_AMOUNT, so no transfer should be created
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
end
