# frozen_string_literal: true

class Admin::BaseController < ActionController::Base
  layout 'admin'

  helper_method :base_props

  private

  def base_props
    {
      current_admin: current_admin&.as_json(only: %i[name]),
      prsdigg: {
        app_id: PrsdiggBot.api.client_id
      }
    }
  end

  def authenticate_admin!
    redirect_to root_path unless current_admin
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
end
