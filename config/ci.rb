# frozen_string_literal: true

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
  # browser-dependent suite instead of failing every run on the network. The
  # gate is a launch smoke test, not mere presence — an installed browser that
  # cannot start (sandbox, missing libs) would fail every system test anyway.
  # CHROME_REQUIRED=1 makes the skip fatal.
  chrome_smoke = "google-chrome-stable --headless --no-sandbox --disable-gpu " \
    "--disable-dev-shm-usage --dump-dom about:blank >/dev/null 2>&1"
  if ENV["CHROME_REQUIRED"] || system(chrome_smoke)
    step "Tests: System", "bin/rails test:system"
  else
    puts ">> Skipping Tests: System - no launchable google-chrome-stable on " \
      "this runner (see the Install Chrome step). Export CHROME_REQUIRED=1 to fail instead."
  end

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
