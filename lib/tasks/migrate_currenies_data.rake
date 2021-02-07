# frozen_string_literal: true

task migrate_currencies_data: :environment do
  Order.where(asset_id: nil).find_each do |order|
    order.update asset_id: order.item.asset_id
  end

  %w[
    3edb734c-6d6f-32ff-ab03-4eb43640c758
    c6d0c728-2624-429b-8e0d-d9d19b6592fa
    43d61dcd-e413-450d-80b8-101d5e903357
    6cfe566e-4aad-470b-8c9a-2fd35b49c68d
    31d2ea9c-95eb-3355-b65b-ba096853bc18
    c94ac88f-4671-3976-b60a-09064f1811e8
    4d8c508b-91c5-375b-92b0-ee702ed2dac5
  ].each do |asset_id|
    Currency.find_or_create_by_asset_id asset_id
  end

  Order.where(change_btc: nil, change_usd: nil).find_each(&:sync_history_price_async)
end
