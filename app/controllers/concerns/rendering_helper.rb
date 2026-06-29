# frozen_string_literal: true

module RenderingHelper
  extend ActiveSupport::Concern

  private

  def render_not_found_page
    @page_title = "404"
    render "errors/not_found", status: :not_found, formats: [ :html ]
  end

  def render_flash(type, message)
    render turbo_stream: turbo_stream.append(
      "flashes",
      partial: "flashes/flash",
      locals: {
        type:,
        message:
      }
    )
  end
end
