# frozen_string_literal: true

module Resolvers
  class AdminPaymentConnectionResolver < AdminBaseResolver
    argument :after, String, required: false
    argument :state, String, required: false
    argument :payer_mixin_uuid, String, required: false

    type Types::PaymentConnectionType, null: false

    def resolve(**params)
      payments =
        if params[:payer_mixin_uuid].present?
          User.find_by(mixin_uuid: params[:payer_mixin_uuid]).payments
        else
          Payment.all
        end

      payments =
        case params[:state]
        when 'paid'
          payments.paid
        when 'completed'
          payments.completed
        when 'refunded'
          payments.refunded
        else
          payments
        end

      payments.order(created_at: :desc)
    end
  end
end
