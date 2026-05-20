# frozen_string_literal: true

class TimeFormatComponent < ApplicationComponent
  def initialize(datetime:, **options)
    super()

    @datetime = datetime
    @class = options[:class]
    @format = options[:format] || 'long'
  end
end
