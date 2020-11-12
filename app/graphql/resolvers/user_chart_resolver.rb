# frozen_string_literal: true

module Resolvers
  class UserChartResolver < BaseResolver
    type String, null: false

    def resolve
      User.group_by_day(:created_at, format: '%y/%m/%d').count.map do |key, value|
        { name: key, value: value }
      end.to_json
    end
  end
end
