# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  layout 'dashboard'

  before_action :authenticate_user!

  private

  def authenticate_user!
    redirect_to login_path(return_to: URI.encode_www_form_component('/dashboard')) unless current_user
  end
end
