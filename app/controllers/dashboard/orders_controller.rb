# frozen_string_literal: true

class Dashboard::OrdersController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'payments'
  end
end
