# frozen_string_literal: true

class API::BaseController < ActionController::API
  include API::RenderingHelper

  around_action :with_locale
  after_action :store_access_token_request
  helper_method :current_user

  class UnauthorizedError < StandardError; end
  class UnprocessableEntityError < StandardError; end

  rescue_from StandardError do |ex|
    Rails.logger.error ex.inspect
    render_internal_server_error ex.message
  end

  rescue_from UnauthorizedError do
    render_unauthorized
  end

  rescue_from UnprocessableEntityError do |ex|
    render_unprocessable_entity ex.message
  end

  rescue_from ActiveRecord::RecordNotFound, ActionController::RoutingError do
    render_not_found
  end

  rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved do |ex|
    render_unprocessable_entity ex.message
  end

  private

  def store_access_token_request
    return unless current_access_token

    current_access_token.update(
      last_request: {
        ip: request.remote_ip,
        url: request.url,
        method: request.request_method.to_s,
        at: Time.current.to_s
      }
    )
  rescue StandardError => e
    Rails.logger.error e.inspect
  end

  def authenticate_user!
    raise UnauthorizedError unless current_user
  end

  def current_access_token
    @current_access_token ||= AccessToken.find_by(value: request.env['HTTP_X_ACCESS_TOKEN'])
  end

  def current_user
    @current_user ||= current_access_token&.user
  end

  def with_locale(&)
    I18n.with_locale(:en, &)
  end
end
