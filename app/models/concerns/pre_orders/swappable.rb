# frozen_string_literal: true

module PreOrders::Swappable
  def pay_url(pay_asset_id = asset_id)
    if pay_asset_id == asset_id
      direct_pay_url
    else
      foxswap_pay_url(pay_asset_id)
    end
  end

  def direct_pay_url
    Addressable::URI.new(
      scheme: 'mixin',
      host: 'pay',
      path: '',
      query_values: [
        ['recipient', payee_id],
        ['trace', trace_id],
        ['memo', memo],
        ['asset', asset_id],
        ['amount', amount.to_f.round(8)]
      ]
    ).to_s
  end

  def foxswap_pay_url(pay_asset_id)
    Addressable::URI.new(
      scheme: 'mixin',
      host: 'codes',
      path: foxswap_pay_code_id(pay_asset_id)
    ).to_s
  end

  def foxswap_pay_code_id(pay_asset_id)
    return if pay_asset_id == asset_id

    QuillBot.api.create_payment(
      asset_id: pay_asset_id,
      trace_id: trace_id,
      memo: fswap_mtg_memo,
      amount: pay_amount(pay_asset_id),
      receivers: Settings.foxswap.mtg_members,
      threshold: Settings.foxswap.mtg_threshold
    )['code_id']
  end

  def fswap_mtg_memo
    r = Foxswap.api.actions(
      user_id: payee_id,
      follow_id: follow_id,
      asset_id: asset_id,
      minimum_fill: order_type == 'reward_article' ? nil : amount
    )

    r['data']['action']
  end

  def pay_amount(pay_asset_id = nil)
    @pay_amount ||=
      case pay_asset_id
      when asset_id
        amount
      else
        begin
          Foxswap.api.pre_order(
            pay_asset_id: pay_asset_id,
            fill_asset_id: asset_id,
            amount: (amount * 1.001).ceil(8).to_f
          )['data']['funds']
        rescue StandardError
          nil
        end
      end
  end
end
