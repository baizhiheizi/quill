# frozen_string_literal: true

module Resolvers
  class AdminBonusConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::BonusConnectionType, null: false

    def resolve(_params = {})
      Bonus.all.order(created_at: :desc)
    end
  end
end
