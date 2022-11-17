# frozen_string_literal: true

class Dashboard::AssetsController < Dashboard::BaseController
  def index
    @tab = params[:tab] || 'token'
  end
end
