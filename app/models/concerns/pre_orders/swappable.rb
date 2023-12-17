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
    QuillBot.api.safe_pay_url(
      members: [QuillBot.api.client_id],
      threshold: 1,
      asset_id: asset_id,
      amount: amount,
      trace_id: trace_id,
      memo: memo
    )
  end

  def foxswap_pay_url(pay_asset_id)
    return if pay_asset_id == asset_id

    route = fswap_route pay_asset_id
    return if route.blank?

    QuillBot.api.safe_pay_url(
      members: Settings.foxswap.mtg_members,
      threshold: Settings.foxswap.mtg_threshold,
      asset_id: pay_asset_id,
      amount: route[:funds],
      trace_id: trace_id,
      memo: fswap_mtg_memo(route[:routes]),
    )
  end

  def fswap_pay_code_id(pay_asset_id)
    return if pay_asset_id == asset_id

    route = fswap_route pay_asset_id
    return if route.blank?

    QuillBot.api.create_payment(
      asset_id: pay_asset_id,
      memo: fswap_mtg_memo(route[:routes]),
      amount: route[:funds],
      receivers: Settings.foxswap.mtg_members,
      threshold: Settings.foxswap.mtg_threshold
    )['code_id']
  end

  def fswap_mtg_memo(route_id = nil)
    r = PandoBot::Lake.api.actions(
      user_id: payee_id,
      follow_id: follow_id,
      asset_id: asset_id,
      route_id: route_id,
      minimum_fill: order_type == 'reward_article' ? nil : amount
    )

    r['data']['action']
  end

  def pay_amount(pay_asset_id = asset_id)
    if pay_asset_id == asset_id
      amount
    else
      fswap_route(pay_asset_id)&.[](:funds)
    end
  end

  def fswap_route(pay_asset_id = nil)
    @fswap_route ||=
      begin
        pairs = Rails.cache.fetch 'pando_lake_routes', expires_in: 5.seconds do
          PandoBot::Lake.api.pairs['data']['pairs']
        end

        routes ||= PandoBot::Lake::PairRoutes.new pairs
        routes.pre_order(
          input_asset: pay_asset_id,
          output_asset: asset_id,
          output_amount: (amount * 1.001).ceil(8).to_f
        )
      rescue StandardError
        nil
      end
  end
end
