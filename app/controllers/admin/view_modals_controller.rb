# frozen_string_literal: true

module Admin
  class ViewModalsController < Admin::BaseController
    def create
      case params[:type]
      when 'create_bonus'
        render :create_bonus
      end
    end
  end
end
