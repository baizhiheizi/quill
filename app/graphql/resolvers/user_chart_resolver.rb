# frozen_string_literal: true

module Resolvers
  class UserChartResolver < BaseResolver
    type String, null: false

    def resolve
      count = 0
      User.group_by_day(:created_at, format: '%y/%m/%d').count.map do |key, value|
        count += value
        { name: key, value: count }
      end.to_json
    end
  end
end
