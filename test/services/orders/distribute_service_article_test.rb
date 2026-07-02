# frozen_string_literal: true

require "test_helper"

class Orders::DistributeServiceArticleTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
    @author = users(:author)
    @reader_one = users(:reader_one)
    @reader_two = users(:reader_two)
    @blocked_reader = users(:blocked_reader)
  end

  # === Memo format coverage ===

  test "buy_article reader_revenue memo is 'Reader revenue from {title}'" do
    with_quill_bot_stub do
      # Two readers so reader_revenue is actually generated.
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

      reader_transfer = order.transfers.find_by(
        transfer_type: :reader_revenue,
        opponent_id: @reader_one.mixin_uuid
      )
      assert reader_transfer, "Reader revenue transfer should exist"
      assert_equal "Reader revenue from #{@article.title}".truncate(70),
                   reader_transfer.memo
    end
  end

  test "buy_article reader_revenue memo is truncated to 70 characters for long titles" do
    # Title is capped at 64 chars by Article validation; "Reader revenue from "
    # (20 chars) + 64 = 84, so the memo still overflows the 70-char truncate.
    long_title_article = Article.create!(
      uuid: SecureRandom.uuid,
      title: ("A" * 64),
      intro: "Long title",
      content: "<p>Long title body for truncation coverage</p>",
      author: @author,
      state: "published",
      platform_revenue_ratio: 0.1,
      readers_revenue_ratio: 0.4,
      author_revenue_ratio: 0.5,
      locale: "en"
    )
    # published_at is set after create so the "frozen attributes once
    # published" guard (which fires when asset_id changes) doesn't reject
    # setup_attributes defaulting asset_id/price.
    long_title_article.update_columns(published_at: 2.days.ago)

    with_quill_bot_stub do
      create_buy_order!(
        article: long_title_article,
        buyer: @reader_one,
        total: 1.0,
        created_at: 3.days.ago
      )
      order = create_buy_order!(
        article: long_title_article,
        buyer: @reader_two,
        total: 2.0,
        created_at: 1.day.ago
      )
      distribute_order!(order)

      reader_transfer = order.transfers.find_by(
        transfer_type: :reader_revenue,
        opponent_id: @reader_one.mixin_uuid
      )
      assert reader_transfer
      assert_operator reader_transfer.memo.length, :<=, 70
      assert_equal "Reader revenue from #{long_title_article.title}".truncate(70),
                   reader_transfer.memo
    end
  end

  test "buy_article reference_revenue memo is base64({t:'CITE',a:ref.uuid,c:item.uuid})" do
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

      decoded = JSON.parse(Base64.decode64(reference_transfer.memo))
      assert_equal "CITE", decoded["t"]
      assert_equal referenced_article.uuid, decoded["a"]
      assert_equal @article.uuid, decoded["c"]
    end
  end

  test "buy_article collection_revenue memo is 'collection revenue from {title}'" do
    with_quill_bot_stub do
      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "Memo Test Collection",
        symbol: "MTC",
        description: "Memo coverage",
        author: @author,
        asset_id: @article.asset_id,
        price: 0.001,
        revenue_ratio: 0.2,
        platform_revenue_ratio: 0.1,
        state: "listed"
      )
      @article.update_columns(
        collection_id: collection.uuid,
        collection_revenue_ratio: 0.1
      )
      @article.reload

      # One subscriber so reader_revenue (collection revenue) is generated.
      create_payment!(
        payer: @reader_one,
        collection: collection,
        order_type: "BUY",
        amount: collection.price
      )

      order = create_buy_order!(article: @article, buyer: @reader_two, total: 1.0)
      distribute_order!(order)

      collection_transfer = order.transfers.find_by(
        transfer_type: :reader_revenue,
        opponent_id: @reader_one.mixin_uuid
      )
      assert collection_transfer, "Collection revenue transfer should exist"
      assert_equal "collection revenue from #{@article.title}".truncate(70),
                   collection_transfer.memo
    end
  end

  test "buy_article author_revenue memo is '{buyer.name} bought {item.title}'" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert author_transfer
      assert_equal "#{@reader_one.name} bought #{@article.title}".truncate(70),
                   author_transfer.memo
    end
  end

  test "buy_article author_revenue memo is truncated to 70 characters for long titles" do
    # Title capped at 64; "Reader One bought " (18 chars) + 64 = 82 > 70.
    long_title_article = Article.create!(
      uuid: SecureRandom.uuid,
      title: ("B" * 64),
      intro: "Long title intro",
      content: "<p>Long title body for truncation coverage</p>",
      author: @author,
      state: "published",
      platform_revenue_ratio: 0.1,
      readers_revenue_ratio: 0.4,
      author_revenue_ratio: 0.5,
      locale: "en"
    )
    long_title_article.update_columns(published_at: 2.days.ago)

    with_quill_bot_stub do
      order = create_buy_order!(
        article: long_title_article,
        buyer: @reader_one,
        total: 1.0
      )
      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert author_transfer
      assert_operator author_transfer.memo.length, :<=, 70
      expected = "#{@reader_one.name} bought #{long_title_article.title}".truncate(70)
      assert_equal expected, author_transfer.memo
    end
  end

  # === Wallet-id branch for buy_article quill_revenue ===

  test "buy_article skips quill_revenue when payment wallet equals bot client_id" do
    # Snapshot whose user_id matches QuillBot.api.client_id makes the service's
    # `payment.wallet_id != QuillBot.api.client_id` guard return false, so no
    # quill_revenue transfer is created.
    bot_client_id = QuillBotStub::FAKE_CLIENT_ID

    with_quill_bot_stub(client_id: bot_client_id) do
      snapshot = MixinNetworkSnapshot.create!(
        snapshot_id: SecureRandom.uuid,
        user_id: bot_client_id,
        asset_id: @article.asset_id,
        amount: 0,
        trace_id: SecureRandom.uuid,
        opponent_id: @reader_one.mixin_uuid,
        transferred_at: Time.current,
        data: ""
      )

      payment = create_payment!(
        payer: @reader_one,
        article: @article,
        order_type: "BUY",
        amount: @article.price
      )
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

  # === Multi-subscriber collection revenue distribution ===

  test "article in collection distributes collection revenue equally to multiple subscribers" do
    with_quill_bot_stub do
      collection = Collection.create!(
        uuid: SecureRandom.uuid,
        name: "Multi Subscriber Collection",
        symbol: "MSC",
        description: "Multi-subscriber collection",
        author: @author,
        asset_id: @article.asset_id,
        price: 0.001,
        revenue_ratio: 0.2,
        platform_revenue_ratio: 0.1,
        state: "listed"
      )
      @article.update_columns(
        collection_id: collection.uuid,
        collection_revenue_ratio: 0.1
      )
      @article.reload

      # Three subscribers
      create_payment!(payer: @reader_one, collection: collection,
                      order_type: "BUY", amount: collection.price)
      create_payment!(payer: @reader_two, collection: collection,
                      order_type: "BUY", amount: collection.price)
      create_payment!(payer: @blocked_reader, collection: collection,
                      order_type: "BUY", amount: collection.price)

      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      distribute_order!(order)

      # _collection_sum = 1.0 * 0.1 = 0.1
      # _collection_avg = 0.1 / 3 ≈ 0.03333333 → .floor(8) = 0.03333333
      expected_avg = ((1.0 * 0.1) / 3).floor(8)
      collection_transfers = order.transfers.where(transfer_type: :reader_revenue)
      assert_equal 3, collection_transfers.count,
                   "One reader_revenue transfer per subscriber"
      collection_transfers.each do |t|
        assert_in_delta expected_avg, t.amount.to_f, 0.000_000_01,
                        "Each subscriber should receive the equal share"
      end
    end
  end

  # === Memo format for cite_article and reward_article author transfers ===

  test "cite_article author_revenue memo is 'Reference revenue from {title}'" do
    with_quill_bot_stub do
      order = create_buy_order!(article: @article, buyer: @reader_one, total: 1.0)
      order.update_columns(order_type: :cite_article)

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert author_transfer, "cite_article should still produce author_revenue"
      assert_equal "Reference revenue from #{@article.title}".truncate(70),
                   author_transfer.memo
    end
  end

  test "reward_article author_revenue memo is '{buyer.name} rewarded {item.title}'" do
    with_quill_bot_stub do
      payment = create_payment!(
        payer: @reader_one,
        article: @article,
        order_type: "REWARD",
        amount: 1.0
      )
      order = payment.order

      distribute_order!(order)

      author_transfer = order.transfers.find_by(transfer_type: :author_revenue)
      assert author_transfer
      assert_equal "#{@reader_one.name} rewarded #{@article.title}".truncate(70),
                   author_transfer.memo
    end
  end

  # === References memo: ref.reference.author.mixin_uuid routing ===
  #
  # Articles no longer provision per-article Mixin wallets (#1797), so
  # reference_revenue routes to the cited article's author Mixin identity
  # rather than the now-absent article wallet.

  test "reference_revenue opponent_id is the reference article author's mixin_uuid" do
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
      assert reference_transfer
      assert_equal referenced_article.author.mixin_uuid, reference_transfer.opponent_id
    end
  end
end
