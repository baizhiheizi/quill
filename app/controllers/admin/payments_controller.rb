# frozen_string_literal: true

module Admin
  class PaymentsController < Admin::BaseController
    def index
      payments = Payment.all
      payments = payments.where(payer_id: params[:payer_id]) if params[:payer_id].present?

      @state = params[:state] || "all"
      payments =
        case @state
        when "all"
          payments
        else
          payments.where(state: @state)
        end

      @order_by = params[:order_by] || "created_at_desc"
      payments =
        case @order_by
        when "created_at_desc"
          payments.order(created_at: :desc)
        when "created_at_asc"
          payments.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      payments =
        payments.ransack(
          {
            id_eq: @query,
            payer_id_eq: @query,
            opponent_id_eq: @query,
            trace_id_eq: @query,
            asset_id_eq: @query
          }.merge(m: "or")
        ).result

      # Eager-load associations consumed by the rendered partial
      # `app/views/admin/payments/_payment.html.erb`:
      #   - `:payer`    → `payment.payer` (admin/users/_field.html.erb)
      #   - `:currency` → `payment.currency.icon_url`, `payment.price_tag`
      #
      # Without these includes each row triggers ~2 SELECTs (payer +
      # currency). For an admin viewing a pagy page of 50 payments, the
      # action runs ~100 SELECTs per request.
      @pagy, @payments = pagy(:countless, payments.includes(:payer, :currency))
    end

    def show
      @payment = Payment.find params[:id]
    end
  end
end
