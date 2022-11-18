# frozen_string_literal: true

class Dashboard::DestinationsController < Dashboard::BaseController
  def show
  end

  def deposit
    @selected = Currency.find_by asset_id: params[:asset_id] if params[:asset_id].present?
  end
end
