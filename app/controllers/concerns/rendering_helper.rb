# frozen_string_literal: true

module RenderingHelper
  extend ActiveSupport::Concern

  private

  def render_flash(type, message)
    render turbo_stream: turbo_stream.append(
      'flashes',
      partial: 'flashes/flash',
      locals: {
        type: type,
        message: message
      }
    )
  end
end
