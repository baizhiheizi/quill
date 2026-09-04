# frozen_string_literal: true

require "test_helper"

# Covers `lib/solid_cache_recovery.rb` and its wiring through
# `config/initializers/solid_cache_failsafe.rb`.
#
# The recovery module exists because the production cache SQLite file can end
# up with a malformed disk image (shared deploy volume, hard kill mid-write),
# after which nothing ever repaired it. These tests exercise the real repair
# against a real (deliberately corrupted) SQLite file so they would catch, for
# example, a Rails upgrade breaking the schema-recreation trick or a sidecar
# (-wal/-shm) no longer being cleaned up.
#
# The module's seams (`cache_db_config`, `cache_pool`, `schema_target`) are
# pointed at a scratch database instead of `SolidCache::Record` so the tests
# never touch the real cache/primary pools.
class SolidCacheRecoveryTest < ActiveSupport::TestCase
  SIDE_CAR_SUFFIXES = [ "", "-wal", "-shm", "-journal" ].freeze

  setup do
    # Unique per test so `establish_connection` always builds a fresh pool
    # instead of reusing one that still holds a connection to a deleted file.
    @db_path = Rails.root.join("tmp/solid_cache_recovery_test_#{SecureRandom.hex(4)}.sqlite3")
    purge_scratch_database
    # The throttle lives in module state and would otherwise leak between tests.
    SolidCacheRecovery.instance_variable_set(:@last_recovery_at, nil)
  end

  teardown { purge_scratch_database }

  module PoolTarget
    def self.for(pool)
      target = Object.new
      target.define_singleton_method(:connection_pool) { pool }
      target.define_singleton_method(:lease_connection) { pool.lease_connection }
      target
    end
  end

  # Throwaway connection owner so the global ActiveRecord::Base /
  # SolidCache::Record connection assignments are never touched.
  class ScratchOwner < ActiveRecord::Base
    self.abstract_class = true
  end

  # Points SolidCacheRecovery at a scratch SQLite database for the duration of
  # the block and yields the scratch pool.
  def with_cache_database(path)
    config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      "test", "cache", { adapter: "sqlite3", database: path.to_s, timeout: 5000 }
    )
    ScratchOwner.establish_connection(config)
    pool = ScratchOwner.connection_pool

    stubs = {
      cache_db_config: -> { config },
      cache_pool: -> { pool },
      schema_target: -> { PoolTarget.for(pool) }
    }
    stub_seams!(stubs)

    yield pool
  ensure
    restore_seams!(stubs || {})
    ScratchOwner.connection_pool.disconnect!
  end

  def stub_seams!(stubs)
    stubs.each do |name, block|
      SolidCacheRecovery.singleton_class.alias_method(:"__original_#{name}", name)
      SolidCacheRecovery.singleton_class.send(:define_method, name, block)
    end
  end

  def restore_seams!(stubs)
    stubs.each_key do |name|
      SolidCacheRecovery.singleton_class.alias_method(name, :"__original_#{name}")
      SolidCacheRecovery.singleton_class.remove_method(:"__original_#{name}")
    end
  end

  # Corrupts the scratch file the way a hard kill mid-write can: garbage where
  # the database image should be, plus a stale WAL sidecar. The pool is
  # disconnected first so the next checkout reopens the file and actually sees
  # the damage.
  def corrupt_database!(pool)
    pool.disconnect!
    File.binwrite(@db_path, "this is not a SQLite database" * 64)
    File.binwrite("#{@db_path}-wal", "stale write-ahead log" * 16)
  end

  def database_quick_check(pool)
    pool.with_connection { |connection| connection.select_value("PRAGMA quick_check(1)") }
  end

  def cache_table_names(pool)
    pool.with_connection { |connection| connection.tables }
  end

  def expire_throttle!
    SolidCacheRecovery.instance_variable_set(
      :@last_recovery_at,
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - SolidCacheRecovery::MIN_RECOVERY_INTERVAL - 1
    )
  end

  def purge_scratch_database
    SIDE_CAR_SUFFIXES.each { |suffix| FileUtils.rm_f("#{@db_path}#{suffix}") }
    FileUtils.rm_f("#{@db_path}.recovery.lock")
  end

  test "corrupt_exception? detects corruption wrapped by ActiveRecord in the cause chain" do
    wrapped = begin
      begin
        raise SQLite3::CorruptException, "database disk image is malformed"
      rescue SQLite3::CorruptException
        raise ActiveRecord::StatementInvalid, "SQLite3::CorruptException: database disk image is malformed"
      end
    rescue ActiveRecord::StatementInvalid => error
      error
    end

    assert SolidCacheRecovery.corrupt_exception?(wrapped)
  end

  test "corrupt_exception? detects bare SQLite corruption errors" do
    assert SolidCacheRecovery.corrupt_exception?(SQLite3::CorruptException.new("database disk image is malformed"))
    assert SolidCacheRecovery.corrupt_exception?(SQLite3::NotADatabaseException.new("file is not a database"))
  end

  test "corrupt_exception? ignores transient and unrelated errors" do
    transient = begin
      raise ActiveRecord::AdapterTimeout, "could not obtain a database connection"
    rescue ActiveRecord::AdapterTimeout => error
      error
    end

    assert_not SolidCacheRecovery.corrupt_exception?(transient)
    assert_not SolidCacheRecovery.corrupt_exception?(ArgumentError.new("unrelated"))
    assert_not SolidCacheRecovery.corrupt_exception?(nil)
  end

  test "recover! rebuilds a corrupt database into a usable cache" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)

      SolidCacheRecovery.recover!(reason: "test")

      assert_equal "ok", database_quick_check(pool), "the rebuilt database must pass quick_check"
      assert_includes cache_table_names(pool), "solid_cache_entries", "the cache schema must be recreated"

      # The rebuilt cache must actually be writable and readable.
      pool.with_connection do |connection|
        connection.execute(<<~SQL.squish)
          INSERT INTO solid_cache_entries (key, value, key_hash, byte_size, created_at)
          VALUES (x'6B6579', x'76616C7565', 42, 5, '2026-01-01 00:00:00')
        SQL
        assert_equal 1, connection.select_value("SELECT count(*) FROM solid_cache_entries")
      end
    end
  end

  test "recover! removes stale -wal and -shm sidecars of the corrupt database" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)
      File.binwrite("#{@db_path}-shm", "stale shared memory" * 8)

      SolidCacheRecovery.recover!(reason: "test")

      assert_equal "ok", database_quick_check(pool)
    end
  end

  test "recover! is throttled to one attempt per MIN_RECOVERY_INTERVAL" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)
      SolidCacheRecovery.recover!(reason: "first")
      assert_equal "ok", database_quick_check(pool)

      corrupt_database!(pool)
      SolidCacheRecovery.recover!(reason: "second within interval")

      assert File.read(@db_path).start_with?("this is not a SQLite database"),
             "a recovery within the throttle interval must not run"
    end
  end

  test "recover! runs again once the throttle interval has elapsed" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)
      SolidCacheRecovery.recover!(reason: "first")
      corrupt_database!(pool)

      expire_throttle!
      SolidCacheRecovery.recover!(reason: "second after interval")

      assert_equal "ok", database_quick_check(pool)
    end
  end

  test "recover! skips the rebuild when another process holds the repair lock" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)

      File.open("#{@db_path}.recovery.lock", File::CREAT | File::RDWR) do |lock|
        lock.flock(File::LOCK_EX)

        SolidCacheRecovery.recover!(reason: "test")

        assert File.read(@db_path).start_with?("this is not a SQLite database"),
               "the rebuild must be left to the process holding the repair lock"
      end
    end
  end

  test "recover! is a no-op when the cache database is not SQLite" do
    corrupt_database!(ScratchOwner.connection_pool)

    postgres_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      "test", "cache", { adapter: "postgresql", database: "safety_probe" }
    )

    stub_seams!(cache_db_config: -> { postgres_config })
    SolidCacheRecovery.recover!(reason: "test")
    restore_seams!(cache_db_config: nil)

    assert File.exist?(@db_path), "a non-SQLite cache config must never trigger the file-based rebuild"
  end

  test "check_at_boot! heals a corrupt database before traffic" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)

      SolidCacheRecovery.check_at_boot!

      assert_equal "ok", database_quick_check(pool)
      assert_includes cache_table_names(pool), "solid_cache_entries"
    end
  end

  test "check_at_boot! leaves a healthy database untouched" do
    with_cache_database(@db_path) do |pool|
      pool.with_connection { |connection| connection.create_table :boot_probe }

      SolidCacheRecovery.check_at_boot!

      assert_includes cache_table_names(pool), "boot_probe", "a healthy database must not be rebuilt"
    end
  end

  test "check_at_boot! does not touch anything when the database file is missing" do
    config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      "test", "cache", { adapter: "sqlite3", database: @db_path.to_s, timeout: 5000 }
    )

    untouched_pool = Object.new
    untouched_pool.define_singleton_method(:with_connection) do |&block|
      flunk "the boot check must not open the database when the file does not exist yet"
    end

    stub_seams!(cache_db_config: -> { config }, cache_pool: -> { untouched_pool })
    SolidCacheRecovery.check_at_boot!
    restore_seams!(cache_db_config: nil, cache_pool: nil)

    assert_not File.exist?(@db_path), "a missing cache file must be left to db:prepare to create"
  end

  test "the store's error_handler reports corruption and triggers recovery" do
    with_cache_database(@db_path) do |pool|
      corrupt_database!(pool)

      corruption = begin
        raise SQLite3::CorruptException, "database disk image is malformed"
      rescue SQLite3::CorruptException => error
        error
      end

      assert_error_reported(SQLite3::CorruptException) do
        SolidCacheRecovery::ERROR_HANDLER.call(method: :expire, returning: nil, exception: corruption)
      end

      assert_equal "ok", database_quick_check(pool), "the expiry-thread corruption must trigger the rebuild"
    end
  end

  test "the store's error_handler does not trigger recovery for transient errors" do
    with_cache_database(@db_path) do |pool|
      pool.with_connection { |connection| connection.create_table :boot_probe }

      transient = begin
        raise ActiveRecord::AdapterTimeout, "could not obtain a database connection"
      rescue ActiveRecord::AdapterTimeout => error
        error
      end

      SolidCacheRecovery::ERROR_HANDLER.call(method: :expire, returning: nil, exception: transient)

      assert_includes cache_table_names(pool), "boot_probe", "transient errors must not rebuild the cache"
    end
  end
end
