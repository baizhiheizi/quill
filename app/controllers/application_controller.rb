# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :base_props

  private

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user = User.find_by(id: session[:current_user_id])
  end

  def user_sign_in(user)
    session[:current_user_id] = user.id
  end

  def user_sign_out
    session[:current_user_id] = nil
    @current_user = nil
  end

  def base_props
    {
      current_user: current_user&.as_json(
        only: %i[name avatar_url mixin_id mixin_uuid banned_at]
      ),
      prsdigg: {
        app_id: PrsdiggBot.api.client_id
      }
    }
  end
end
