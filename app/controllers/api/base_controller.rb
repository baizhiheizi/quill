# frozen_string_literal: true

class API::BaseController < ActionController::API
  include API::RenderingHelper

  around_action :with_locale
  after_action :store_access_token_request
  helper_method :current_user

  rescue_from StandardError do |ex|
    Rails.logger.error ex.inspect
    render_internal_server_error
  end

  rescue_from ActiveRecord::RecordNotFound do
    render_not_found
  end

  rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved do
    render_unprocessable_entity
  end

  private

  def store_access_token_request
    return unless current_access_token

    current_access_token.update(
      last_request: {
        ip: request.remote_ip,
        url: request.url,
        method: request.request_method,
        at: Time.current
      }
    )
  end

  def authenticate_user!
    render_unauthorized unless current_user
  end

  def current_access_token
    @_current_access_token = AccessToken.find_by(value: request.env['HTTP_X_ACCESS_TOKEN'])
  end

  def current_user
    @_current_user = current_access_token&.user
  end

  def with_locale(&action)
    I18n.with_locale(:en, &action)
  end
end
