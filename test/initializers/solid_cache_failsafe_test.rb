# frozen_string_literal: true

require "test_helper"

# Covers `config/initializers/solid_cache_failsafe.rb`.
#
# Production context: Solid Cache's `Store::Failsafe#failsafe` only rescues a
# hardcoded list of "transient" ActiveRecord errors
# (`TRANSIENT_ACTIVE_RECORD_ERRORS`). A real-world outage surfaced that this
# list does NOT include `ActiveRecord::StatementInvalid`, which is the wrapper
# ActiveRecord puts around the native `SQLite3::CorruptException` raised when
# the cache database file is malformed. Without the initializer every
# read/write/delete call against a corrupt cache file 500s the request, even
# though a cache miss would be a perfectly fine fallback.
#
# The initializer prepends a module on `SolidCache::Store::Failsafe` that
# expands the rescue list to include `ActiveRecord::StatementInvalid` and
# routes rescued errors through `Rails.error.report` (handled, warning).
# These tests pin both behaviors so a future gem upgrade or refactor can't
# silently re-break the page.
class SolidCacheFailsafeStatementInvalidExtTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::ErrorReporterAssertions

  # The Solid Cache gem ships Failsafe as a module, not a class. We need a
  # concrete object to call the private `failsafe` on, so we instantiate a
  # bare `SolidCache::Store` and reach into its included modules via
  # `send`. (We do not actually hit SQLite — the block is responsible for
  # raising or returning.)
  setup do
    @store = SolidCache::Store.new
  end

  test "failsafe returns the supplied default when the block raises ActiveRecord::StatementInvalid (e.g. SQLite3::CorruptException)" do
    simulated_corruption = ActiveRecord::StatementInvalid.new("SQLite3::CorruptException: database disk image is malformed")

    result = @store.send(:failsafe, :read_entry, returning: nil) { raise simulated_corruption }

    assert_nil result, "A cache read against a corrupt DB must degrade to a cache miss (nil), not propagate the error."
  end

  test "failsafe still rescues the original TRANSIENT_ACTIVE_RECORD_ERRORS list" do
    SolidCache::Store::Failsafe::TRANSIENT_ACTIVE_RECORD_ERRORS.each do |klass|
      # Build a stand-in instance (no real DB connection needed because
      # `failsafe` only matches on class).
      transient = klass.new("simulated transient #{klass.name}")

      result = @store.send(:failsafe, :read_entry, returning: nil) { raise transient }

      assert_nil result, "Expected #{klass.name} to still be rescued by failsafe after the initializer runs."
    end
  end

  test "failsafe still propagates unrelated exceptions so they aren't silently swallowed" do
    unrelated = ArgumentError.new("unrelated bug")

    error = assert_raises(ArgumentError) do
      @store.send(:failsafe, :read_entry, returning: nil) { raise unrelated }
    end

    assert_equal "unrelated bug", error.message
  end

  test "rescued corruption is reported to Rails.error as handled warning with cache context" do
    simulated_corruption = ActiveRecord::StatementInvalid.new("SQLite3::CorruptException: database disk image is malformed")

    report = assert_error_reported(ActiveRecord::StatementInvalid) do
      @store.send(:failsafe, :read_entry, returning: :miss) { raise simulated_corruption }
    end

    assert_predicate report, :handled?
    assert_equal :warning, report.severity
    assert_equal "SolidCache", report.context[:cache_store]
    assert_equal :read_entry, report.context[:cache_method]
  end
end
