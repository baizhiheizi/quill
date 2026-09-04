# frozen_string_literal: true

module NotifierHelpers
  def ensure_notification_setting!(user)
    user.create_notification_setting! if user.notification_setting.blank?
    user.notification_setting
  end

  def with_mixin_bot_delivery_stub
    with_quill_bot_stub do
      api = QuillBot.api
      api.define_singleton_method(:base_message_params) { |params| params.deep_stringify_keys }
      yield
    end
  end

  def deliver_notifier!(notifier_class, record:, recipient:, **params)
    notifier_class.with(record: record, **params).deliver(recipient)
  end

  def notification_for(recipient)
    recipient.notifications.order(:id).last
  end

  # -- shared builders -------------------------------------------------------
  #
  # One recipe per notification kind, so the parameterised suite in
  # `notification_delivery_test.rb` can deliver every kind without each file
  # re-deriving its own fixtures.

  def create_collection!(author:, name: "Featured Bundle")
    Collection.create!(
      uuid: SecureRandom.uuid,
      name: name,
      symbol: "FB",
      description: "Test collection",
      author: author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end

  def create_order!(item:, buyer:, order_type: :buy_article)
    trace_id = SecureRandom.uuid
    payment = nil

    stub_notifications! do
      payment = build_payment_record(
        amount: item.price,
        asset_id: item.asset_id,
        payer: buyer,
        memo: build_payment_memo(
          type: "BUY",
          article: item.is_a?(Article) ? item : nil,
          collection: item.is_a?(Collection) ? item : nil
        ),
        state: "completed",
        trace_id: trace_id
      )
    end

    Order.create!(
      buyer: buyer,
      seller: item.author,
      item: item,
      payment: payment,
      order_type: order_type,
      trace_id: payment.trace_id,
      asset_id: item.asset_id,
      total: item.price,
      value_btc: 0,
      value_usd: 0,
      state: "completed"
    )
  end

  def create_refunded_payment!(payer:, article:, pre_order: nil)
    trace_id = SecureRandom.uuid
    refund_snapshot_id = SecureRandom.uuid
    payment = nil

    stub_notifications! do
      payment = build_payment_record(
        amount: article.price,
        asset_id: article.asset_id,
        payer: payer,
        memo: build_payment_memo(type: "BUY", article: article, follow_id: pre_order&.follow_id),
        state: "refunded",
        trace_id: trace_id
      )
    end

    Transfer.create!(
      transfer_type: :payment_refund,
      source: payment,
      amount: payment.amount,
      asset_id: article.asset_id,
      opponent_id: payer.mixin_uuid,
      trace_id: SecureRandom.uuid,
      snapshot: { "snapshot_id" => refund_snapshot_id }
    )

    # `Transfer#snapshot_id` reads from the `snapshot` JSON, and the notifier
    # calls `payment.refund_transfer.snapshot_id` — reset the association cache
    # to expose the refund transfer created above.
    payment.association(:refund_transfer).reset

    payment
  end

  def create_transfer!(recipient:, transfer_type: :author_revenue, amount: 0.0001)
    Transfer.create!(
      trace_id: SecureRandom.uuid,
      transfer_type: transfer_type,
      amount: amount,
      asset_id: currencies(:btc).asset_id,
      opponent_id: recipient.mixin_uuid,
      wallet: mixin_network_users(:article_wallet),
      snapshot: { "snapshot_id" => SecureRandom.uuid }
    )
  end

  def create_subscribe_action!(subscriber:, target:)
    Action.skip_callback :create, :after, :notify_target
    Action.create!(
      action_type: "subscribe",
      user: subscriber,
      target: target,
      user_type: "User",
      target_type: "User"
    )
  ensure
    Action.set_callback :create, :after, :notify_target
  end

  # Stubs `with(...)` on a notifier so a factory's own fan-out adds no
  # deliveries or rows the caller did not ask for.
  def stub_notifier_delivery!(*notifier_classes)
    delivery = Object.new
    delivery.define_singleton_method(:deliver) { |*_args| true }
    delivery.define_singleton_method(:deliver_later) { |*_args| true }

    originals = notifier_classes.to_h { |klass| [ klass, klass.method(:with) ] }
    notifier_classes.each { |klass| klass.define_singleton_method(:with) { |*_args| delivery } }

    yield
  ensure
    originals&.each { |klass, method| klass.define_singleton_method(:with, method) }
  end

  # Returns `[record, params]` — the `record:` and params `kind` is delivered
  # with — so one suite can exercise every notification kind.
  def build_notification_delivery!(kind, recipient:)
    author = users(:author)
    buyer = users(:reader_one)
    article = articles(:published_paid)

    case kind.to_sym
    when :article_published
      [ article, { article: article } ]
    when :article_bought
      order = create_order!(item: article, buyer: buyer)
      [ order, { order: order } ]
    when :article_rewarded
      order = create_order!(item: article, buyer: buyer)
      [ order, { order: order } ]
    when :collection_listed
      collection = create_collection!(author: author)
      [ collection, { collection: collection } ]
    when :collection_bought
      order = create_order!(item: create_collection!(author: author), buyer: buyer)
      [ order, { order: order } ]
    when :comment_created
      comment = stub_notifier_delivery!(CommentCreatedNotifier) do
        Comment.create!(author: buyer, commentable: article, content: "Great article!")
      end
      [ comment, { comment: comment } ]
    when :tagging_created
      tagging = taggings(:published_paid_web3)
      [ tagging, { tagging: tagging } ]
    when :transfer_processed
      transfer = create_transfer!(recipient: recipient)
      [ transfer, { transfer: transfer } ]
    when :order_created
      order = create_order!(item: article, buyer: buyer)
      [ order, { order: order } ]
    when :payment_created
      payment = create_payment!(payer: recipient, article: article)
      [ payment, { payment: payment } ]
    when :payment_refunded
      payment = create_refunded_payment!(payer: recipient, article: article)
      [ payment, { payment: payment } ]
    when :subscribe_user_action_created
      action = create_subscribe_action!(subscriber: buyer, target: recipient)
      [ action, { action: action } ]
    when :user_connected, :user_safe_registration
      [ recipient, { user: recipient } ]
    else
      raise ArgumentError, "no delivery recipe for #{kind.inspect}"
    end
  end

  private

  def build_payment_record(amount:, asset_id:, payer:, memo:, state:, trace_id:)
    payment = Payment.new(
      amount: amount,
      memo: memo,
      raw: {
        "amount" => amount.to_s,
        "asset_id" => asset_id,
        "memo" => memo,
        "opponent_id" => payer.mixin_uuid,
        "snapshot_id" => SecureRandom.uuid,
        "trace_id" => trace_id
      },
      asset_id: asset_id,
      snapshot_id: SecureRandom.uuid,
      trace_id: trace_id,
      payer: payer,
      state: state
    )
    payment.define_singleton_method(:generate_order!) { }
    payment.save!(validate: false)
    payment
  end
end
