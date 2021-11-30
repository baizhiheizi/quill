# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type =
      if current_user.blank?
        'login'
      else
        params[:type]
      end

    case type
    when 'login'
      render :login
    end
  end
end
