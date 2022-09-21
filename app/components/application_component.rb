# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include Turbo::FramesHelper
  include Pagy::Frontend
end
