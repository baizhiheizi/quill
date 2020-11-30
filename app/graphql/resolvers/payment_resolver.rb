# frozen_string_literal: true

module Resolvers
  class PaymentResolver < MyBaseResolver
    argument :trace_id, ID, required: true

    type Types::PaymentType, null: true

    def resolve(trace_id:)
      Payment.find_by(trace_id: trace_id)
    end
  end
end
