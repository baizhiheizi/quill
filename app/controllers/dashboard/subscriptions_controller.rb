# frozen_string_literal: true

class Dashboard::SubscriptionsController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'subscribing'
  end
end
