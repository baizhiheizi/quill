# frozen_string_literal: true

require "tmpdir"

# Run using bin/ci

CI.run do
  step "Setup", "env RAILS_ENV=test bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Lint: Design system", "bin/lint-design-system --no-fail"

  step "Style: JavaScript", "bun run lint-check"
  step "Tests: JavaScript", "bun run test:js"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # The "Install Chrome for system tests" workflow step degrades to a
  # ::warning when the runner's egress cannot fetch a browser; here we skip the
  # browser-dependent suite instead of failing every run on the environment.
  # The gate is a real chromedriver session — the exact launch path test:system
  # uses — not mere browser presence, so "installed but cannot start" also
  # skips. CHROME_REQUIRED=1 makes the skip fatal.
  chrome_launches = begin
    require "selenium-webdriver"
    if ENV["CI"]
      # NOTE: a single-quoted-looking `command -v ...` would be exec'd directly
      # by Ruby (no shell metacharacters -> no shell) and fail with ENOENT.
      driver_version = `chromedriver --version 2>&1`.lines.first&.strip
      puts ">> chromedriver in PATH: #{driver_version || "none"}"
      puts ">> google-chrome-stable: #{`google-chrome-stable --version 2>&1`.strip}"
    end
    options = Selenium::WebDriver::Chrome::Options.new(
      args: [
        "--headless", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage",
        "--user-data-dir=#{Dir.mktmpdir("chrome-probe", File.join(ENV.fetch("HOME", Dir.tmpdir), ".cache"))}"
      ]
    )
    Selenium::WebDriver.for(:chrome, options: options).quit
    true
  rescue StandardError => e
    puts ">> Browser launch probe failed: #{e.class}: #{e.message.to_s.lines.first&.strip}"
    false
  end

  if ENV["CHROME_REQUIRED"] || chrome_launches
    step "Tests: System", "bin/rails test:system"
  else
    puts ">> Skipping Tests: System - chromedriver cannot launch a browser on " \
      "this runner (see the Install Chrome step diagnostics). Export CHROME_REQUIRED=1 to fail instead."
  end

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
