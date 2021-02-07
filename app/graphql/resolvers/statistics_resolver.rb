# frozen_string_literal: true

module Resolvers
  class StatisticsResolver < BaseResolver
    type Types::StatisticsType, null: false

    def resolve
      {
        users_count: User.count,
        articles_count: Article.count,
        author_revenue_total: Transfer.author_revenue_total_in_usd,
        reader_revenue_total: Transfer.reader_revenue_total_in_usd
      }
    end
  end
end
