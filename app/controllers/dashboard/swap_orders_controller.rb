# frozen_string_literal: true

class Dashboard::SwapOrdersController < Dashboard::BaseController
  def index
    @pagy, @swap_orders = pagy current_user.swap_orders.order(created_at: :desc)
  end
end
