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
end
