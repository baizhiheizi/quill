# frozen_string_literal: true

# Static pages (specs/011-comprehensive-ui-refactor) — rendered under the
# public layout so they share the masthead + design system with the rest of
# the public reader experience.
class PagesController < ApplicationController
  layout "public"

  def fair
    render "pages/fair"
  end

  def rules
    render "pages/rules"
  end
end
