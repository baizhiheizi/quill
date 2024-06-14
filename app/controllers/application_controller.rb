# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Localizable
  include RenderingHelper

  before_action :ensure_launched!
  before_action :prepare_exception_notifier

  helper_method :current_session
  helper_method :current_user
  helper_method :current_locale
  helper_method :from_mixin_messenger?
  helper_method :requesting_modal?
  around_action :with_locale

  add_flash_types :success, :warning, :danger, :info

  private

  def ensure_launched!
    redirect_to landing_path unless launched?
  end

  def launched?
    return true if Settings.launch_time.blank?
    return true if current_user&.accessable?

    Time.current > Time.zone.parse(Settings.launch_time)
  end

  def authenticate_user!
    redirect_to root_path if current_user.blank?
  end

  def current_user
    @current_user ||= current_session&.user
  end

  def current_session
    return if session[:current_session_id].blank?

    @current_session ||= Session.find_by(uuid: session[:current_session_id])
  end

  def user_sign_in(user_session)
    session[:current_session_id] = user_session.uuid
  end

  def user_sign_out
    session[:current_session_id] = nil
    @current_user = nil
    @current_session = nil
  end

  def with_locale(&)
    current_user.update(locale: current_locale) if current_user && current_locale && current_user.locale != current_locale
    locale = current_user&.locale || current_locale&.to_sym || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def from_mixin_messenger?
    request&.user_agent&.match?(/Mixin|Links/)
  end

  def current_locale
    @current_locale ||= session[:current_locale].presence || current_user&.locale.presence || browser_locale.presence || I18n.default_locale
  end

  def requesting_modal?
    request.headers['Turbo-Frame'] == 'modal'
  end

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] = {
      current_user:
    }
  end
end
