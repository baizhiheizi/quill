# frozen_string_literal: true

# Quill design-system core. Exposes:
#   - DesignSystem::Lint     — static analyzer (lib/design_system/lint.rb)
#   - DesignSystem::Primitives — registry of shared partials (lib/design_system/primitives.rb)
#   - DesignSystem::Violation — value object for lint findings (lib/design_system/violation.rb)
#
# The reference page lives at app/views/design_system/ and is rendered by
# DesignSystemController#show at /design-system.
#
# See specs/011-comprehensive-ui-refactor/contracts/ for the contracts each
# module + primitive must satisfy.

module DesignSystem
end

require_relative "design_system/violation"
require_relative "design_system/primitives"
require_relative "design_system/lint"
