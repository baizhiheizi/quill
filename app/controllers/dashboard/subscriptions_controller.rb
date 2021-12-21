# frozen_string_literal: true

class Dashboard::SubscriptionsController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'subscribings'
  end
end
