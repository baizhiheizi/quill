# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Localizable

  before_action :ensure_launched!

  helper_method :current_user
  helper_method :current_locale
  helper_method :from_mixin_messenger?
  around_action :with_locale

  add_flash_types :success, :warning, :danger, :info

  private

  def ensure_launched!
    redirect_to landing_path unless launched?
  end

  def launched?
    return true if Settings.launch_time.blank?
    return true if current_user&.mixin_id_in_whitelist?

    Time.current > Time.zone.parse(Settings.launch_time)
  end

  def authenticate_user!
    render 'view_modals/login' if current_user.blank?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:current_user_id])
  end

  def user_sign_in(user)
    session[:current_user_id] = user.id
  end

  def user_sign_out
    session[:current_user_id] = nil
    @current_user = nil
  end

  def with_locale(&action)
    current_user.update(locale: current_locale) if current_user && current_locale && current_user.locale != current_locale
    locale = current_user&.locale || current_locale&.to_sym || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def from_mixin_messenger?
    request&.user_agent&.match?(/Mixin|Links/)
  end

  def current_locale
    @current_locale ||= (session[:current_locale] || current_user&.locale || browser_locale || I18n.default_locale)
  end
end
