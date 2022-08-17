# frozen_string_literal: true

class QrcodeComponent < ApplicationComponent
  def initialize(url:, image_classes: '')
    super

    @url = url
    @image_classes = image_classes
  end
end
