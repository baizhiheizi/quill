# frozen_string_literal: true

class Dashboard::HomeController < Dashboard::BaseController
  def index
    redirect_to dashboard_readings_path
  end

  def readings
    @tab = params[:tab] || 'bought'
    @active_page = 'readings'
  end

  def authorings
    @tab = params[:tab] || 'drafted'
    @active_page = 'authorings'
  end

  def settings
    @tab = params[:tab] || 'profile'
    @active_page = 'settings'
  end

  def wallet
    @tab =
      if current_user.mvm_eth?
        params[:tab] || 'token'
      else
        params[:tab] || 'nft'
      end

    @active_page = 'wallet'
  end
end
