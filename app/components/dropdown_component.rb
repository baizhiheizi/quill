# frozen_string_literal: true

class DropdownComponent < ApplicationComponent
  renders_one :button

  def initialize(**options)
    super()

    @class = options[:class] || ''
  end
end
