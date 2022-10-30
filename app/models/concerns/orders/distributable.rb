# frozen_string_literal: true

module Orders::Distributable
  MINIMUM_AMOUNT = 0.0000_0001

  def distribute_async
    DistributeOrderWorker.perform_async trace_id
  end

  def early_orders
    @early_orders ||=
      item
      .orders
      .where(order_type: %i[buy_article reward_article])
      .where('id < ? and created_at < ?', id, created_at)
      .order(created_at: :desc)
  end

  def early_orders_with_the_same_currency
    @early_orders_with_the_same_currency ||=
      early_orders.where.not(asset_id: asset_id).blank?
  end

  def collect_early_readers
    readers = {}
    early_orders.each do |_order|
      readers[_order.buyer.mixin_uuid] ||= []
      readers[_order.buyer.mixin_uuid].push _order.trace_id
    end

    readers
  end

  def distribute!
    case item
    when Article
      distribute_article_order!
    when Collection
      distribute_collection_order!
    end

    complete! if paid?
  end

  # transfer revenue to collection author
  def distribute_collection_order!
    # create quill transfer
    if payment.wallet_id != QuillBot.api.client_id
      transfers.create_with(
        queue_priority: :low,
        wallet_id: payment.wallet_id,
        transfer_type: :quill_revenue,
        opponent_id: QuillBot.api.client_id,
        asset_id: revenue_asset_id,
        amount: quill_amount.to_s,
        memo: Base64.encode64({
          t: 'REVENUE',
          a: item.uuid
        }.to_json)
      ).find_or_create_by!(
        trace_id: MixinBot::Utils.unique_uuid(trace_id, QuillBot.api.client_id)
      )
    end

    # create author transfer
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
      trace_id: QuillBot.api.unique_conversation_id(trace_id, item.author.mixin_uuid)
    )
  end

  # transfer revenue to article author and readers
  def distribute_article_order!
    # the share for invested readers before
    amount = total * item.readers_revenue_ratio

    # total investment
    sum =
      if early_orders_with_the_same_currency
        early_orders.sum(:total)
      else
        early_orders.sum(:value_btc)
      end

    # create quill transfer
    return unless quill_amount.positive?

    if payment.wallet_id == QuillBot.api.client_id
      transfers.create_with(
        queue_priority: :default,
        wallet_id: QuillBot.api.client_id,
        transfer_type: :default,
        opponent_id: distributor_wallet_id,
        asset_id: revenue_asset_id,
        amount: (total - quill_amount).to_f.to_s,
        memo: "Distribute order #{trace_id}".truncate(70)
      ).find_or_create_by!(
        trace_id: MixinBot::Utils.unique_uuid(distributor_wallet_id, trace_id)
      )
    else
      transfers.create_with(
        queue_priority: :low,
        wallet_id: distributor_wallet_id,
        transfer_type: :quill_revenue,
        opponent_id: QuillBot.api.client_id,
        asset_id: revenue_asset_id,
        amount: quill_amount.to_s,
        memo: Base64.encode64({
          t: 'REVENUE',
          a: item.uuid
        }.to_json)
      ).find_or_create_by!(
        trace_id: MixinBot::Utils.unique_uuid(trace_id, QuillBot.api.client_id)
      )
    end

    # create reader transfer
    _readers_amount = 0
    collect_early_readers.each do |reader_id, order_ids|
      share =
        if early_orders_with_the_same_currency
          early_orders.where(trace_id: order_ids).sum(:total)
        else
          early_orders.where(trace_id: order_ids).sum(:value_btc)
        end

      # ignore if amount is less than minium amout for Mixin Network
      _amount = (amount * share.to_f / sum).floor(8)
      next if (_amount - MINIMUM_AMOUNT).negative?

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

    # create references revenue transfer
    _references_amount = 0
    if item.article_references.count.positive?
      item.article_references.each do |ref|
        _ref_amount = (total * ref.revenue_ratio).floor(8)
        next if (_ref_amount - MINIMUM_AMOUNT).negative?

        transfers.create_with(
          queue_priority: :low,
          transfer_type: :reference_revenue,
          wallet_id: distributor_wallet_id,
          opponent_id: ref.reference.wallet_id,
          asset_id: revenue_asset_id,
          amount: _ref_amount,
          memo: Base64.encode64({
            t: 'CITE',
            a: ref.reference.uuid,
            c: item.uuid
          }.to_json)
        ).find_or_create_by(
          trace_id: QuillBot.api.unique_conversation_id(trace_id, ref.reference.uuid)
        )

        _references_amount += _ref_amount
      end
    end

    # create collection revenue transfer
    _collection_amount = 0.0
    _collection_sum =
      if item.collection_revenue_ratio.positive? && item.collection.present?
        (total * item.collection_revenue_ratio).floor(8)
      else
        0.0
      end

    _collection_orders_count =
      if item.collection.present?
        item.collection.orders.where(order_type: :buy_collection).count
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
      item.collection.orders.where(order_type: :buy_collection).find_each do |_order|
        transfers.create_with(
          queue_priority: :low,
          wallet_id: distributor_wallet_id,
          transfer_type: :reader_revenue,
          opponent_id: _order.buyer.mixin_uuid,
          asset_id: revenue_asset_id,
          amount: _collection_avg_amount,
          memo: "collection revenue from #{item.title}".truncate(70)
        ).find_or_create_by!(
          trace_id: QuillBot.api.unique_conversation_id(trace_id, _order.trace_id)
        )
        _collection_amount += _collection_avg_amount
      end
    end

    # create author transfer
    author_revenue_transfer_memo =
      if cite_article?
        "Reference revenue from #{item.title}"
      else
        "#{buyer.name} #{buy_article? ? 'bought' : 'rewarded'} #{item.title}"
      end
    transfers.create_with(
      queue_priority: :low,
      wallet_id: distributor_wallet_id,
      transfer_type: :author_revenue,
      opponent_id: item.author.mixin_uuid,
      asset_id: revenue_asset_id,
      amount: (total - _readers_amount - quill_amount - _references_amount - _collection_amount).floor(8),
      memo: author_revenue_transfer_memo.truncate(70)
    ).find_or_create_by!(
      trace_id: QuillBot.api.unique_conversation_id(trace_id, item.author.mixin_uuid)
    )
  end

  private

  def quill_amount
    @quill_amount ||= (total * item.platform_revenue_ratio).floor(8)
  end

  def distributor_wallet_id
    @distributor_wallet_id ||=
      if payment.wallet_id == QuillBot.api.client_id
        buyer.wallet_id
      else
        payment.wallet_id
      end
  end

  def revenue_asset_id
    # payment maybe swapped
    @revenue_asset_id ||= payment.swap_order&.fill_asset_id || payment.asset_id
  end
end
