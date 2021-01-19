# frozen_string_literal: true

module Resolvers
  class ArticleChartResolver < BaseResolver
    type String, null: false

    def resolve
      count = 0
      Article.only_published.group_by_day(:created_at, format: '%y/%m/%d').count.map do |key, value|
        count += value
        { name: key, value: count }
      end.to_json
    end
  end
end
