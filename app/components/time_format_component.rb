# frozen_string_literal: true

class TimeFormatComponent < ApplicationComponent
  def initialize(datetime:)
    super

    @datetime = datetime
  end
end
