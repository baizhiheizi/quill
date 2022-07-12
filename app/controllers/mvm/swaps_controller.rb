# frozen_string_literal: true

class MVM::SwapsController < MVM::BaseController
  def create
    @pay_asset = Currency.find_or_create_by asset_id: params[:pay_asset_id]
    @fill_asset = Currency.find_or_create_by asset_id: params[:fill_asset_id]
  end
end
