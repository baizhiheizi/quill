# frozen_string_literal: true

class EmptyComponent < ApplicationComponent
  def initialize(text:)
    super

    @text = text
  end
end
