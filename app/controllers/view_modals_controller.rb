# frozen_string_literal: true

class ViewModalsController < ApplicationController
  def create
    type = params[:type]

    render type
  end
end
