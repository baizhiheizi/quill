# frozen_string_literal: true

class Dashboard::AssetsController < Dashboard::BaseController
  def index
    @token_assets = current_user.token_assets
  end
end
