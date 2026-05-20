# frozen_string_literal: true

module CommerceHelpers
  def stub_notifications!
    delivery = Object.new
    delivery.define_singleton_method(:deliver) { |*_args| true }
    delivery.define_singleton_method(:deliver_later) { |*_args| true }

    notification_classes = [
      PaymentCreatedNotification,
      PaymentRefundedNotification,
      OrderCreatedNotification
    ]
    originals = notification_classes.to_h { |klass| [ klass, klass.method(:with) ] }

    notification_classes.each do |klass|
      klass.define_singleton_method(:with) { |*_args| delivery }
    end

    yield
  ensure
    originals&.each { |klass, method| klass.define_singleton_method(:with, method) }
  end

  def build_payment_memo(type:, article: nil, collection: nil, follow_id: nil)
    payload = { "t" => type }
    payload["a"] = article.uuid if article
    payload["l"] = collection.uuid if collection
    payload["f"] = follow_id if follow_id
    Base64.encode64(payload.to_json)
  end

  def create_payment!(payer:, article: nil, collection: nil, order_type: "BUY", amount: nil, asset_id: nil, follow_id: nil)
    item = article || collection
    amount ||= item.price
    asset_id ||= item.asset_id
    trace_id = SecureRandom.uuid
    snapshot_id = SecureRandom.uuid
    memo = build_payment_memo(type: order_type, article: article, collection: collection, follow_id: follow_id)

    raw = {
      "amount" => amount.to_s,
      "asset_id" => asset_id,
      "memo" => memo,
      "opponent_id" => payer.mixin_uuid,
      "snapshot_id" => snapshot_id,
      "trace_id" => trace_id,
      "data" => memo
    }

    stub_notifications! do
      with_quill_bot_stub do
        Payment.create!(
          amount: amount,
          raw: raw,
          asset_id: asset_id,
          snapshot_id: snapshot_id,
          trace_id: trace_id,
          payer: payer
        )
      end
    end
  end

  def distribute_order!(order)
    order.define_singleton_method(:all_transfers_generated?) { true }
    order.distribute!
  end

  def create_buy_order!(article:, buyer:, total: nil, created_at: Time.current)
    total ||= article.price
    trace_id = SecureRandom.uuid
    payment = nil

    stub_notifications! do
      payment = Payment.new(
        amount: total,
        raw: {
          "amount" => total.to_s,
          "asset_id" => article.asset_id,
          "memo" => build_payment_memo(type: "BUY", article: article),
          "opponent_id" => buyer.mixin_uuid,
          "snapshot_id" => SecureRandom.uuid,
          "trace_id" => trace_id
        },
        asset_id: article.asset_id,
        snapshot_id: SecureRandom.uuid,
        trace_id: trace_id,
        payer: buyer,
        state: "completed"
      )
      payment.define_singleton_method(:generate_order!) { }
      payment.save!(validate: false)
    end

    Order.create!(
      buyer: buyer,
      seller: article.author,
      item: article,
      payment: payment,
      order_type: :buy_article,
      trace_id: payment.trace_id,
      asset_id: article.asset_id,
      total: total,
      value_btc: article.currency.price_btc.to_f * total.to_f,
      value_usd: article.currency.price_usd.to_f * total.to_f,
      created_at: created_at,
      updated_at: created_at
    )
  end
end
