# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start "rails" do
    skip "/test/"
    skip "/config/"
    skip "/db/"
  end
end

ENV["RAILS_ENV"] ||= "test"

# Split editor/reader bundles live in gitignored app/assets/builds/. Stub
# them before boot so Propshaft can resolve stylesheet/javascript tags in CI.
require "fileutils"
builds = File.expand_path("../app/assets/builds", __dir__)
FileUtils.mkdir_p(builds)
%w[application.css application.js editor.css editor.js reader.css reader.js].each do |name|
  path = File.join(builds, name)
  File.write(path, "/* test stub */\n") unless File.exist?(path)
end

require_relative "../config/environment"
require "rails/test_help"

%w[
  support/quill_bot_stub.rb
  support/commerce_helpers.rb
  support/notifier_helpers.rb
  support/integration_test_case.rb
].each { |f| require_relative f }

Rails.application.routes.default_url_options[:host] = "www.example.com"

module ActiveSupport
  class TestCase
    fixtures :all

    include ActiveJob::TestHelper
    include CommerceHelpers
    include NotifierHelpers
    include QuillBotStub

    setup do
      @previous_queue_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
    end

    teardown do
      clear_enqueued_jobs
      clear_performed_jobs
      ActiveJob::Base.queue_adapter = @previous_queue_adapter
    end

    def sign_in(user)
      @test_session = Session.create!(
        user: user,
        uuid: SecureRandom.uuid,
        info: { "provider" => "mixin" }
      )
      @test_session
    end

    def api_headers(access_token)
      { "HTTP_X_ACCESS_TOKEN" => access_token.value }
    end

    def perform_all_jobs(&block)
      perform_enqueued_jobs(only: nil, &block)
    end
  end
end

class JobTestCase < ActiveSupport::TestCase
  def stub_class_method(klass, method_name, implementation)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &implementation)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end
end
