# frozen_string_literal: true

require "test_helper"

# An explicitly-built headless-Chrome driver: identical flags to Rails'
# `:headless_chrome` plus the standard CI pair (--no-sandbox: the SUID sandbox
# needs user namespaces many CI runners don't have; --disable-dev-shm-usage: a
# small /dev/shm chokes Chrome), and a per-process verbose chromedriver log
# printed on failure so "Chrome instance exited" is diagnosable in CI logs.
Capybara.register_driver :headless_chrome_verbose do |app|
  log_path = "/tmp/chromedriver-#{Process.pid}.log"
  service = Selenium::WebDriver::Chrome::Service.new(args: [ "--verbose", "--log-path=#{log_path}" ])
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--disable-search-engine-choice-screen")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  Capybara::Selenium::Driver.new(app, browser: :chrome, service: service, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_chrome_verbose, screen_size: [ 1400, 1400 ]
end

Minitest.after_run do
  logs = Dir["/tmp/chromedriver-*.log"]
  return if logs.empty? || !ENV["CI"]

  warn "\n===== chromedriver verbose logs (tails) ====="
  logs.each do |path|
    warn "--- #{path}"
    warn File.readlines(path).last(40).join
  end
end
