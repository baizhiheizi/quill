# frozen_string_literal: true

module Resolvers
  class AdminPaymentConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::PaymentConnectionType, null: false

    def resolve(_params = {})
      Payment.all.order(created_at: :desc)
    end
  end
end
