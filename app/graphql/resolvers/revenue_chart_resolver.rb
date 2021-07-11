# frozen_string_literal: true

module Resolvers
  class RevenueChartResolver < BaseResolver
    type String, null: false

    def resolve
      Order.group_by_month(:created_at, format: '%Y-%m').sum(:value_usd).map do |key, value|
        { name: key, value: (value * Order::PLATFORM_RATIO).to_f }
      end.to_json
    end
  end
end
