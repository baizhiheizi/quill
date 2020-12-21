# frozen_string_literal: true

module Resolvers
  class MyStatisticsResolver < MyBaseResolver
    type Types::UserStatisticsType, null: false

    def resolve
      current_user.statistics
    end
  end
end
