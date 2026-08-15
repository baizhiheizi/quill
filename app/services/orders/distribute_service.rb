# frozen_string_literal: true

class Orders::DistributeService
  MINIMUM_AMOUNT = 0.0000_0001

  def self.call(order)
    new(order).call
  end

  def initialize(order)
    @order = order
  end

  def call
    # Two paths can dispatch distribution concurrently for the same order:
    # `after_create_commit :distribute_async` and `Orders::BatchDistributeJob`
    # (which re-dispatches every paid order every 10 minutes). Without a row
    # lock both workers can pass the `completed?` guard and attempt to create
    # the same transfers, racing on the `transfers.trace_id` unique constraint.
    # Acquire `FOR UPDATE`, then re-check the AASM state under the lock so only
    # one worker proceeds to completion.
    @order.class.transaction do
      @order.lock!
      return if @order.completed?

      case @order.item
      when Article
        distribute_article_order!
      when Collection
        distribute_collection_order!
      end

      @order.complete_with_observability! if @order.paid?
    end
  end

  private

  attr_reader :order

  delegate :transfers, :trace_id, :payment, :total, :buyer, :item,
           :cite_article?, :buy_article?,
           :early_orders, :early_orders_with_the_same_currency, :collect_early_readers,
           to: :order

  def distribute_collection_order!
    if payment.wallet_id != QuillBot.api.client_id
      transfers.create_with(
        queue_priority: :low,
        wallet_id: payment.wallet_id,
        transfer_type: :quill_revenue,
        opponent_id: QuillBot.api.client_id,
        asset_id: revenue_asset_id,
        amount: quill_amount.to_s,
        memo: Base64.encode64({
          t: "REVENUE",
          a: item.uuid
        }.to_json)
      ).find_or_create_by!(
        trace_id: MixinBot::Utils.unique_uuid(trace_id, QuillBot.api.client_id)
      )
    end

    author_revenue_transfer_memo = "#{buyer.name} bought #{item.name}"

    transfers.create_with(
      queue_priority: :low,
      wallet_id: payment.wallet_id,
      transfer_type: :author_revenue,
      opponent_id: item.author.mixin_uuid,
      asset_id: revenue_asset_id,
      amount: (total - quill_amount).floor(8),
      memo: author_revenue_transfer_memo.truncate(70)
    ).find_or_create_by!(
      trace_id: MixinBot::Utils.unique_uuid(trace_id, item.author.mixin_uuid)
    )
  end

  def distribute_article_order!
    amount = total * item.readers_revenue_ratio

    readers_share_column = early_orders_with_the_same_currency ? :total : :value_btc

    sum = early_orders.sum(readers_share_column)

    if quill_amount.positive? && payment.wallet_id != QuillBot.api.client_id
      transfers.create_with(
        queue_priority: :low,
        wallet_id: distributor_wallet_id,
        transfer_type: :quill_revenue,
        opponent_id: QuillBot.api.client_id,
        asset_id: revenue_asset_id,
        amount: quill_amount.to_s,
        memo: Base64.encode64({
          t: "REVENUE",
          a: item.uuid
        }.to_json)
      ).find_or_create_by!(
        trace_id: MixinBot::Utils.unique_uuid(trace_id, QuillBot.api.client_id)
      )
    end

    # Compute per-reader share in a single grouped query rather than issuing
    # one `early_orders.where(trace_id: order_ids).sum(...)` aggregate per
    # reader group. With R readers this saves R-1 SQL round trips.
    # `unscope(:order)` is required because `early_orders` carries
    # `.order(created_at: :desc)`, which PostgreSQL rejects in a `GROUP BY`
    # context (PG::GroupingError: column must appear in GROUP BY).
    share_by_trace_id = early_orders.unscope(:order).group(:trace_id).sum(readers_share_column)
    reader_shares = collect_early_readers.transform_values do |order_ids|
      order_ids.sum { |trace_id| share_by_trace_id[trace_id].to_f }
    end

    _readers_amount = 0
    reader_shares.each do |reader_id, share|
      _amount = (amount * share / sum).floor(8)
      next if (_amount - MINIMUM_AMOUNT).negative?

      order_ids = collect_early_readers.fetch(reader_id)
      salt = order_ids.push trace_id
      transfers.create_with(
        queue_priority: :low,
        wallet_id: distributor_wallet_id,
        transfer_type: :reader_revenue,
        opponent_id: reader_id,
        asset_id: revenue_asset_id,
        amount: _amount.to_f.to_s,
        memo: "Reader revenue from #{item.title}".truncate(70)
      ).find_or_create_by!(
        trace_id: MixinBot::Utils.unique_uuid(*salt)
      )

      _readers_amount += _amount
    end

    _references_amount = 0
    # Eager-load each ArticleReference's referenced Article and its author in
    # a fixed 3 queries (article_references + references + authors) instead of
    # the prior `2R + 1` pattern (count + N article_references + N authors).
    references = item.article_references.includes(reference: :author)
    if references.any?
      references.each do |ref|
        _ref_amount = (total * ref.revenue_ratio).floor(8)
        next if (_ref_amount - MINIMUM_AMOUNT).negative?

        transfers.create_with(
          queue_priority: :low,
          transfer_type: :reference_revenue,
          wallet_id: distributor_wallet_id,
          opponent_id: ref.reference.author.mixin_uuid,
          asset_id: revenue_asset_id,
          amount: _ref_amount,
          memo: Base64.encode64({
            t: "CITE",
            a: ref.reference.uuid,
            c: item.uuid
          }.to_json)
        ).find_or_create_by(
          trace_id: QuillBot.api.unique_uuid(trace_id, ref.reference.uuid)
        )

        _references_amount += _ref_amount
      end
    end

    _collection_amount = 0.0
    collection = item.collection
    _collection_sum =
      if item.collection_revenue_ratio.positive? && collection.present?
        (total * item.collection_revenue_ratio).floor(8)
      else
        0.0
      end

    _collection_orders_count =
      if collection.present?
        collection.orders.where(order_type: :buy_collection).count
      else
        0
      end
    _collection_avg_amount =
      if _collection_orders_count.positive?
        (_collection_sum / _collection_orders_count).floor(8)
      else
        0.0
      end

    if (_collection_avg_amount - MINIMUM_AMOUNT).positive?
      collection.orders.includes(:buyer).where(order_type: :buy_collection).find_each do |_order|
        transfers.create_with(
          queue_priority: :low,
          wallet_id: distributor_wallet_id,
          transfer_type: :reader_revenue,
          opponent_id: _order.buyer.mixin_uuid,
          asset_id: revenue_asset_id,
          amount: _collection_avg_amount,
          memo: "collection revenue from #{item.title}".truncate(70)
        ).find_or_create_by!(
          trace_id: QuillBot.api.unique_uuid(trace_id, _order.trace_id)
        )
        _collection_amount += _collection_avg_amount
      end
    end

    author_revenue_amount = (total - _readers_amount - quill_amount - _references_amount - _collection_amount).floor(8)
    return if (author_revenue_amount - MINIMUM_AMOUNT).negative?

    author_revenue_transfer_memo =
      if cite_article?
        "Reference revenue from #{item.title}"
      else
        "#{buyer.name} #{buy_article? ? 'bought' : 'rewarded'} #{item.title}"
      end
    author_mixin_uuid = item.author.mixin_uuid
    transfers.create_with(
      queue_priority: :low,
      wallet_id: distributor_wallet_id,
      transfer_type: :author_revenue,
      opponent_id: author_mixin_uuid,
      asset_id: revenue_asset_id,
      amount: author_revenue_amount,
      memo: author_revenue_transfer_memo.truncate(70)
    ).find_or_create_by!(
      trace_id: QuillBot.api.unique_uuid(trace_id, author_mixin_uuid)
    )
  end

  def quill_amount
    @quill_amount ||= (total * item.platform_revenue_ratio).floor(8)
  end

  def distributor_wallet_id
    @distributor_wallet_id ||= QuillBot.api.client_id
  end

  def revenue_asset_id
    @revenue_asset_id ||= payment.asset_id
  end
end
