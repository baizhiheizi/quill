# frozen_string_literal: true

class Widget::BaseController < ApplicationController
  include Pagy::Backend

  before_action :set_x_frame_options

  layout 'widget'

  private

  def set_x_frame_options
    response.headers['X-Frame-Options'] = 'ALLOWALL'
  end
end
