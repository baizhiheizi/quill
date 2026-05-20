# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include Turbo::FramesHelper
  include Pagy::Frontend
  include InlineSvg::ActionView::Helpers

  # ViewComponent 4 removed the catch-all Base#initialize; accept and discard args from subclasses.
  def initialize(*_args, **_kwargs)
    super()
  end
end
