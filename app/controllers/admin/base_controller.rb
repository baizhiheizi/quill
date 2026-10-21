# frozen_string_literal: true

class Admin::BaseController < ActionController::Base
  include Pagy::Method

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

  # Admin index actions pick a sort/filter scope with a `case` on a query
  # parameter. An unrecognised value left that scope `nil`, which raised on
  # the next line and turned the request into a 500. Matching the parameter
  # against an allow-list first keeps the `case` total.
  def allowed_param(name, default, allowed)
    params[name].presence_in(allowed) || default
  end
end
