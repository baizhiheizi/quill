# frozen_string_literal: true

module Admin
  class CollectiblesController < Admin::BaseController
    def index
      @collectibles = Collectible.all.order(updated_at: :desc)
    end

    def show
      @collectible = Collectible.find_by metahash: params[:metahash]
    end
  end
end
