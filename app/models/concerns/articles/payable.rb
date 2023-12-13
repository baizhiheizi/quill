# frozen_string_literal: true

module Articles::Payable
  extend ActiveSupport::Concern

  def payment_trace_id(user)
    return if user.blank?

    # generate a unique trace ID for paying
    # avoid duplicate payment
    candidate = QuillBot.api.unique_uuid(uuid, user.mixin_uuid)
    loop do
      break unless Payment.exists?(trace_id: candidate) || PreOrder.exists?(trace_id: candidate, state: %i[paid expired])

      candidate = QuillBot.api.unique_uuid(uuid, candidate)
    end

    candidate
  end

  def buy_url(user, pay_asset_id = asset_id)
    amount = buy_payment_amount pay_asset_id
    return if amount.blank?

    trace_id = payment_trace_id user

    pay_url user, pay_asset_id, amount, buy_payment_memo, trace_id
  end

  def reward_url(user, pay_asset_id, amount, trace_id)
    pay_url user, pay_asset_id, amount, reward_payment_memo, trace_id
  end

  def pay_url(user, pay_asset_id, amount, memo, trace_id)
    if use.has_safe?
      QuillBot.api.safe_pay_url(
        members: [QuillBot.api.client_id],
        threshold: 1,
        asset_id: pay_asset_id,
        amount: amount,
        trace_id: trace_id,
        memo: memo
      )
    else
      Addressable::URI.new(
        scheme: 'mixin',
        host: 'pay',
        path: '',
        query_values: [
          ['recipient', user&.wallet_id || wallet_id],
          ['trace', trace_id],
          ['memo', memo],
          ['asset', pay_asset_id],
          ['amount', amount.to_r.to_f]
        ]
      ).to_s
    end
  end

  def buy_payment_amount(pay_asset_id)
    case pay_asset_id
    when asset_id
      price
    else
      begin
        pairs = Rails.cache.fetch 'pando_lake_routes', expires_in: 5.seconds do
          PandoBot::Lake.api.pairs['data']['pairs']
        end

        routes ||= PandoBot::Lake::PairRoutes.new pairs
        routes.pre_order(
          input_asset: pay_asset_id,
          output_asset: asset_id,
          output_amount: (price * 1.001).ceil(8).to_r.to_f
        )[:funds]
      rescue StandardError
        nil
      end
    end
  end

  def buy_payment_memo
    Base64.urlsafe_encode64({ t: 'BUY', a: uuid }.to_json)
  end

  def reward_payment_memo
    Base64.urlsafe_encode64({ t: 'REWARD', a: uuid }.to_json)
  end

  def mixpay_supported?
    return true if free?

    asset_id.in?(Mixpay.api.settlement_asset_ids)

    # Mixpay.api.quote_assets_cached.find(&->(asset) { asset['assetId'] == asset_id && price >= asset['minQuoteAmount'].to_f && price <= asset['maxQuoteAmount'].to_f }).present?
  end
end
