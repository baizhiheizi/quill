# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# second_level_cache 2.7.x find_target arity mismatch with Rails 8.1 association reader
if defined?(SecondLevelCache::ActiveRecord::Associations::BelongsToAssociation)
  module SecondLevelCacheRails81FindTargetCompat
    def find_target(_skip_statement_cache = nil)
      super()
    end
  end

  [
    SecondLevelCache::ActiveRecord::Associations::BelongsToAssociation,
    SecondLevelCache::ActiveRecord::Associations::HasOneAssociation
  ].each { |mod| mod.prepend(SecondLevelCacheRails81FindTargetCompat) }
end

%w[
  support/quill_bot_stub.rb
  support/commerce_helpers.rb
  support/notifier_helpers.rb
  support/integration_test_case.rb
].each { |f| require_relative f }

Rails.application.routes.default_url_options[:host] = "www.example.com"

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

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
end
