# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  before_action :authenticate_user!, :set_page_meta

  private

  def authenticate_user!
    redirect_to login_path(return_to: URI.encode_www_form_component('/dashboard')) if current_user.blank?
  end

  def set_page_meta
    @page_title = [t('dashboard'), current_user&.name].join('-')
  end
end
