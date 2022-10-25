# frozen_string_literal: true

class Collections::FormComponent < ApplicationComponent
  def initialize(collection:)
    super

    @collection = collection
  end
end
