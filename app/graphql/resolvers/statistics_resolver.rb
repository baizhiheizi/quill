# frozen_string_literal: true

module Resolvers
  class StatisticsResolver < BaseResolver
    type Types::StatisticsType, null: false

    def resolve
      {
        users_count: User.count,
        articles_count: Article.count,
        author_revenue_amount: Transfer.where(transfer_type: :author_revenue).sum(:amount),
        reader_revenue_amount: Transfer.where(transfer_type: :reader_revenue).sum(:amount)
      }
    end
  end
end
