# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    redirect_to login_path(return_to: URI.encode_www_form_component('/dashboard')) if current_user.blank?
  end

  def authenticate_user_mvm_eth!
    redirect_back fallback_location: root_path unless current_user.mvm_eth?
  end
end
