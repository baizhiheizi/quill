# frozen_string_literal: true

module API::RenderingHelper
  extend ActiveSupport::Concern

  private

  def render_ok(data = nil)
    data ||= {}
    render json: data, status: :ok
  end

  def render_created(data = nil)
    data ||= {}
    render json: data, status: :created
  end

  def render_no_content
    head :no_content
  end

  def render_unauthorized(message = nil)
    message ||= 'unauthorized'
    render json: { message: message }, status: :unauthorized
  end

  def render_forbidden(message = nil)
    message ||= 'Forbidden'
    render json: { message: message }, status: :forbidden
  end

  def render_bad_request(message = nil)
    message ||= 'Bad request'
    render json: { message: message }, status: :bad_request
  end

  def render_not_found(message = nil)
    message ||= 'Not found'
    render json: { message: message }, status: :not_found
  end

  def render_unprocessable_entity(message = nil)
    message ||= 'Unprocessable_entity'
    render json: { message: message }, status: :unprocessable_entity
  end

  def render_internal_server_error(message = nil)
    message ||= 'Internal server error'
    render json: { message: message }, status: :internal_server_error
  end
end
