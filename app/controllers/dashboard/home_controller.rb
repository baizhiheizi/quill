# frozen_string_literal: true

class Dashboard::HomeController < Dashboard::BaseController
  def index; end

  def readings
    @tab = params[:tab] || 'bought'
  end

  def authorings
    @tab = params[:tab] || 'drafted'
  end

  def settings
    @tab = params[:tab] || 'profile'
  end
end
