# frozen_string_literal: true

class DropdownComponent < ApplicationComponent
  renders_one :button

  def initialize(params = {})
    super

    @class = params[:class]
  end
end
