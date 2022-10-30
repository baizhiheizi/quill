# frozen_string_literal: true

class Collectings::FormComponent < ApplicationComponent
  def initialize(collecting)
    super

    @collecting = collecting
  end
end
