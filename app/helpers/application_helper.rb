# frozen_string_literal: true

module ApplicationHelper
  include InlineSvg::ActionView::Helpers
  include UiHelper

  # Renders an external image URL without passing bare strings to Propshaft.
  def remote_image_tag(source, options = {})
    return if source.blank?

    source = source.to_s
    return unless source.start_with?("http://", "https://", "//", "/")

    options = options.symbolize_keys
    options[:loading] = "lazy" if options.delete(:lazy)
    image_tag(source, **options)
  end
end
