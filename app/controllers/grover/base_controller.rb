# frozen_string_literal: true

class Grover::BaseController < ApplicationController
  before_action :authenticate!

  layout 'grover'

  private

  def authenticate!
    raise unless Rails.application.credentials.dig(:grover, :token) == params[:token]
  end
end
