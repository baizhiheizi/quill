# frozen_string_literal: true

module Mutations
  class AdminDeliverBonusMutation < AdminBaseMutation
    argument :id, ID, required: true

    type Types::BonusType

    def resolve(id:)
      bonus = Bonus.find(id)
      bonus.deliver!
      bonus
    end
  end
end
