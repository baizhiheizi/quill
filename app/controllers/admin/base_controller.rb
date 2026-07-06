# frozen_string_literal: true

class Admin::BaseController < ActionController::Base
  include Pagy::Method
  include UserFieldPreloads

  before_action :authenticate_admin!

  layout "admin"

  helper_method :current_admin

  private

  def authenticate_admin!
    redirect_to admin_login_path if current_admin.blank?
  end

  def current_admin
    @current_admin ||= session[:current_admin_id] && Administrator.find_by(id: session[:current_admin_id])
  end

  def admin_sign_in(admin)
    session[:current_admin_id] = admin.id
  end

  def admin_sign_out
    session[:current_admin_id] = nil
    @current_admin = nil
  end

  # Backwards-compatible alias for the preload chain — moved to
  # `UserFieldPreloads#user_field_preloads` so the dashboard surface can
  # share the exact same eager-load shape. Existing admin controllers
  # continue to call `admin_user_field_preloads` and remain unchanged.
  alias_method :admin_user_field_preloads, :user_field_preloads
end
