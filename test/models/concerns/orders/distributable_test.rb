# frozen_string_literal: true

require "test_helper"

# Covers the `Orders::Distributable` concern shared by `Order`.
#
# Public surface tested:
#
# - `distribute_async` — enqueues `Orders::DistributeJob` with the order's
#   `trace_id`. The job performs `Order#distribute!` later.
#
# - `distribute!` — synchronous delegation to `Orders::DistributeService.call`.
#   Side effects on `transfers` and `state` are covered in
#   `test/models/order_test.rb` and `test/services/orders/`; here we only
#   pin the delegation contract.
#
# - `early_orders` — the SQL scope that powers reader-revenue distribution.
#   Restricts to `buy_article` + `reward_article` order types on the same
#   polymorphic `item`, strictly before this order (id < self.id AND
#   created_at < self.created_at), ordered by `created_at` DESC.
#
# - `early_orders_with_the_same_currency` — predicate memoized as a boolean.
#   True when there are no early orders OR all early orders use this
#   order's `asset_id`. False when any early order uses a different
#   `asset_id`. The current order itself is excluded by `early_orders`.
#
# - `collect_early_readers` — pure-Ruby map from buyer `mixin_uuid` to an
#   array of `trace_id`s, preserving the `early_orders` ordering.
#
# Why a dedicated file: the concern owns five non-trivial methods used by
# the read-revenue pipeline. `test/models/order_test.rb` focuses on the
# end-to-end distribution behavior (transfer counts, idempotency, etc.);
# the branches below — the strict `id < ? and created_at < ?` window,
# the same-currency predicate's memoization, and the buyer grouping —
# have no individual assertions elsewhere.
class Orders::DistributableTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @author = users(:author)
    @reader_one = users(:reader_one)
    @reader_two = users(:reader_two)
    @blocked_reader = users(:blocked_reader)
  end

  # Order.create! runs through validations, which include a uniqueness check
  # on (order_type, buyer_id, item_id, item_type) for buy_article / buy_collection.
  # Many tests below create multiple buy orders on the same (article, buyer)
  # pair to exercise early-order branches; bypass validations to keep the
  # fixtures honest without fighting the model.
  def create_buy_order_raw!(article:, buyer:, total:, created_at:, order_type: :buy_article, asset_id: nil)
    Order.new(
      buyer: buyer,
      seller: article.author,
      item: article,
      payment: nil,
      order_type: order_type,
      trace_id: SecureRandom.uuid,
      asset_id: asset_id || article.asset_id,
      total: total,
      value_btc: 0.0,
      value_usd: 0.0,
      created_at: created_at,
      updated_at: created_at
    ).tap { |o| o.save!(validate: false) }
  end

  # --- distribute_async ---

  test "distribute_async enqueues Orders::DistributeJob with the order's trace_id" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)

      assert_enqueued_with(job: Orders::DistributeJob, args: [ order.trace_id ]) do
        order.distribute_async
      end
    end
  end

  # --- distribute! ---

  test "distribute! delegates to Orders::DistributeService.call(self)" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      service_called_with = nil
      Orders::DistributeService.singleton_class.define_method(:call) do |arg|
        service_called_with = arg
        # No-op: bypass the real distribute path so we don't mutate transfers.
      end

      order.distribute!

      assert_same order, service_called_with
    ensure
      Orders::DistributeService.singleton_class.send(:remove_method, :call)
      Orders::DistributeService.singleton_class.define_method(:call) { |order| new(order).call }
    end
  end

  # --- early_orders ---

  test "early_orders is empty for the first buyer" do
    with_quill_bot_stub do
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)

      assert_empty order.early_orders
    end
  end

  test "early_orders includes prior buy_article and reward_article orders on the same item" do
    with_quill_bot_stub do
      older_buy = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                         created_at: 3.days.ago)
      older_reward = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 0.5,
                                           created_at: 2.days.ago, order_type: :reward_article)
      order = create_buy_order_raw!(article: @article, buyer: @blocked_reader, total: 1.0,
                                    created_at: 1.day.ago)

      ids = order.early_orders.pluck(:id)
      assert_includes ids, older_buy.id
      assert_includes ids, older_reward.id
    end
  end

  test "early_orders excludes buy_collection and cite_article order types" do
    with_quill_bot_stub do
      # Both filtered at the SQL layer.
      buy_collection = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                             created_at: 3.days.ago, order_type: :buy_collection)
      cite_order = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 0,
                                         created_at: 2.days.ago, order_type: :cite_article)
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)

      ids = order.early_orders.pluck(:id)
      assert_not_includes ids, buy_collection.id
      assert_not_includes ids, cite_order.id
    end
  end

  test "early_orders restricts to the same polymorphic item" do
    with_quill_bot_stub do
      other_article = articles(:published_free)
      other = create_buy_order_raw!(article: other_article, buyer: @reader_one, total: 1.0,
                                    created_at: 3.days.ago)
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)

      assert_not_includes order.early_orders.pluck(:id), other.id
    end
  end

  test "early_orders orders by created_at descending" do
    with_quill_bot_stub do
      older = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 5.days.ago)
      newer = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                                    created_at: 2.days.ago)
      order = create_buy_order_raw!(article: @article, buyer: @blocked_reader, total: 1.0,
                                    created_at: 1.day.ago)

      assert_equal [ newer.id, older.id ], order.early_orders.pluck(:id)
    end
  end

  test "early_orders excludes the order itself and any later orders" do
    with_quill_bot_stub do
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)
      later = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                                    created_at: 1.day.from_now)

      ids = order.early_orders.pluck(:id)
      assert_not_includes ids, order.id
      assert_not_includes ids, later.id
    end
  end

  # --- early_orders_with_the_same_currency ---

  test "early_orders_with_the_same_currency is true when there are no early orders" do
    with_quill_bot_stub do
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)

      assert order.early_orders_with_the_same_currency
    end
  end

  test "early_orders_with_the_same_currency is true when all early orders share asset_id" do
    with_quill_bot_stub do
      create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                            created_at: 3.days.ago)
      create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                            created_at: 2.days.ago)
      order = create_buy_order_raw!(article: @article, buyer: @blocked_reader, total: 1.0,
                                    created_at: 1.day.ago)

      assert order.early_orders_with_the_same_currency
    end
  end

  test "early_orders_with_the_same_currency is false when any early order uses a different asset_id" do
    with_quill_bot_stub do
      foreign = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                      created_at: 3.days.ago)
      foreign.update_columns(asset_id: SecureRandom.uuid)
      order = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                                    created_at: 1.day.ago)

      assert_not order.early_orders_with_the_same_currency
    end
  end

  test "early_orders_with_the_same_currency memoizes its boolean result" do
    with_quill_bot_stub do
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)

      first = order.early_orders_with_the_same_currency
      # Adding early orders after memoization must NOT flip the cached value.
      create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                            created_at: 2.days.ago)
      foreign = create_buy_order_raw!(article: @article, buyer: @blocked_reader, total: 1.0,
                                      created_at: 3.days.ago)
      foreign.update_columns(asset_id: SecureRandom.uuid)

      assert_equal first, order.early_orders_with_the_same_currency
    end
  end

  # --- collect_early_readers ---

  test "collect_early_readers is empty when there are no early orders" do
    with_quill_bot_stub do
      order = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 1.day.ago)

      assert_empty order.collect_early_readers
    end
  end

  test "collect_early_readers groups trace_ids by buyer mixin_uuid" do
    with_quill_bot_stub do
      a1 = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                 created_at: 3.days.ago, order_type: :reward_article)
      a2 = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                 created_at: 2.days.ago)
      b1 = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                                 created_at: 4.days.ago)
      order = create_buy_order_raw!(article: @article, buyer: @blocked_reader, total: 1.0,
                                    created_at: 1.day.ago)

      readers = order.collect_early_readers
      assert_equal [ a2.trace_id, a1.trace_id ], readers[@reader_one.mixin_uuid]
      assert_equal [ b1.trace_id ], readers[@reader_two.mixin_uuid]
    end
  end

  test "collect_early_readers preserves the early_orders created_at-desc ordering per buyer" do
    with_quill_bot_stub do
      older = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 5.days.ago, order_type: :reward_article)
      newer = create_buy_order_raw!(article: @article, buyer: @reader_one, total: 1.0,
                                    created_at: 2.days.ago)
      order = create_buy_order_raw!(article: @article, buyer: @reader_two, total: 1.0,
                                    created_at: 1.day.ago)

      # newer comes first because early_orders orders by created_at DESC.
      assert_equal [ newer.trace_id, older.trace_id ],
                   order.collect_early_readers[@reader_one.mixin_uuid]
    end
  end
end
