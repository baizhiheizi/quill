# frozen_string_literal: true

HighVoltage.configure do |config|
  config.route_drawer = HighVoltage::RouteDrawers::Root

  # specs/011-comprehensive-ui-refactor — render /fair and /rules under the
  # public layout so they share the masthead + design system with the rest
  # of the public reader experience, instead of inheriting the dashboard
  # `application` layout (which has the dashboard rail, not the masthead).
  config.layout = "public"
end
