# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    @page_title = '404'
    render status: :not_found
  end

  def internal_server_error
    @page_title = '500'
    render status: :internal_server_error
  end

  def unprocessable_entity
    @page_title = '422'
    render status: :unprocessable_entity
  end

  def not_acceptable
    @page_title = '406'
    render status: :not_acceptable
  end
end
