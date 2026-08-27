# frozen_string_literal: true

# Renders the in-app design-system reference page at /design-system.
#
# Visibility: development-only. The page is never served in production
# environments (any of `Rails.env.production?`). This is internal
# documentation for engineers and AI agents working on the codebase; the
# public-facing design system contract lives at
# `specs/011-comprehensive-ui-refactor/contracts/` and is reviewed via PR,
# not a public URL.

class DesignSystemController < ApplicationController
  skip_before_action :ensure_launched!
  before_action :ensure_development_only!

  def show
    @page_title = "Design System"
    @primitives = DesignSystem::Primitives::Registry.all
    render "design_system/index"
  end

  private

  def ensure_development_only!
    return unless Rails.env.production?

    # In production, redirect to root with a generic 404-style alert so the
    # route doesn't even hint at the page's existence.
    redirect_to root_path, status: :not_found
  end
end
