# frozen_string_literal: true

class ModalComponent < ApplicationComponent
  def initialize(title:, backdrop: 'default', classes: '')
    @title = title
    @backdrop = backdrop
    @classes = classes
  end
end
