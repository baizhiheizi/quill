# frozen_string_literal: true

module Resolvers
  class MyPaymentConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::PaymentConnectionType, null: false

    def resolve(_params = {})
      current_user.payments.order(created_at: :desc)
    end
  end
end
