# frozen_string_literal: true

module RenderingHelper
  extend ActiveSupport::Concern

  private

  def render_not_found_page
    @page_title = "404"
    render "errors/not_found", status: :not_found, formats: [ :html ]
  end
end
