# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :base_props
  around_action :with_locale

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
        only: %i[name avatar_url mixin_id mixin_uuid banned_at locale]
      )&.merge(
        wallet_id: current_user.wallet_id,
        unread_notifications_count: current_user.unread_notifications_count
      ),
      prsdigg: {
        app_id: PrsdiggBot.api.client_id
      }
    }
  end

  def with_locale(&action)
    locale = current_user&.locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
