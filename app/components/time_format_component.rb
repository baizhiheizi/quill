# frozen_string_literal: true

class TimeFormatComponent < ApplicationComponent
  def initialize(params = {})
    super

    @datetime = params[:datetime]
    @class = params[:class]
    @format = params[:format] || 'long'
  end
end
