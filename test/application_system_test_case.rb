# frozen_string_literal: true

require "tmpdir"
require "fileutils"

require "test_helper"

# One Chrome profile per test process: parallel workers are separate
# processes, sessions within a process run one at a time.
PROFILE_DIR = Dir.mktmpdir("chrome-profile", File.join(ENV.fetch("HOME", Dir.tmpdir), ".cache"))

# An explicitly-built headless-Chrome driver: identical flags to Rails'
# `:headless_chrome` plus the standard CI pair (--no-sandbox: the SUID sandbox
# needs user namespaces many CI runners don't have; --disable-dev-shm-usage: a
# small /dev/shm chokes Chrome), a profile under $HOME (chromedriver's /tmp
# default can be unwritable on hardened runners — the difference between
# "Chrome instance exited" and a working standalone launch), and a per-process
# verbose chromedriver log printed on failure so launches are diagnosable.
Capybara.register_driver :headless_chrome_verbose do |app|
  log_path = "/tmp/chromedriver-#{Process.pid}.log"
  service = Selenium::WebDriver::Chrome::Service.new(args: [ "--verbose", "--log-path=#{log_path}" ])
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--disable-search-engine-choice-screen")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--user-data-dir=#{PROFILE_DIR}")
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
