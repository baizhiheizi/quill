# frozen_string_literal: true

class Dashboard::SettingsController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'profile'
  end
end
