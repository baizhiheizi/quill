# frozen_string_literal: true

class Dashboard::SubscriptionsController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'subscribing_users'
  end
end
