# frozen_string_literal: true

class ModalComponent < ApplicationComponent
  def initialize(title:, backdrop: 'default', classes: '')
    super

    @title = title
    @backdrop = backdrop
    @classes = classes
  end
end
