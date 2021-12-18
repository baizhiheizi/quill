# frozen_string_literal: true

class Dashboard::PaymentsController < Dashboard::BaseController
  def index
    @pagy, @payments = pagy current_user.payments.order(created_at: :desc)
  end
end
