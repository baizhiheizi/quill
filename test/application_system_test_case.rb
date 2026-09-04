# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |driver_options|
    # Standard CI flags: the sandbox needs user namespaces the runner may not
    # have ("Chrome instance exited"), and a small /dev/shm chokes Chrome.
    driver_options.add_argument("--no-sandbox")
    driver_options.add_argument("--disable-dev-shm-usage")
  end
end
