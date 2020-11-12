# frozen_string_literal: true

module Resolvers
  class RevenueChartResolver < BaseResolver
    type String, null: false

    def resolve
      Order.group_by_day(:created_at, format: '%y/%m/%d').sum(:total).map do |key, value|
        { name: key, value: (value * Order::PRSDIGG_RATIO).to_f }
      end.to_json
    end
  end
end
