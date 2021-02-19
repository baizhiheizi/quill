# frozen_string_literal: true

class API::BaseController < ActionController::Base
  include API::RenderingHelper

  skip_before_action :verify_authenticity_token
  layout false

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

  helper_method :current_user
  around_action :with_locale

  def authenticate_user!
    render_unauthorized unless current_user
  end

  def current_user
    @_current_user = AccessToken.find_by(value: request.env['HTTP_X_ACCESS_TOKEN'])&.user
  end

  def with_locale(&action)
    I18n.with_locale(:en, &action)
  end
end
