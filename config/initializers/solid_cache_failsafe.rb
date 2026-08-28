# frozen_string_literal: true

# Make Solid Cache survive a corrupted cache database.
#
# Why this exists:
#   The cache lives in a SQLite file (storage/production_cache.sqlite3) that
#   every long-running process shares through the deploy volume (web, jobs and
#   blaze all mount /rails/storage — see config/deploy.yml). A hard kill
#   mid-write during a deploy can leave that file with a malformed disk image,
#   after which every query touching the damaged pages raises
#   SQLite3::CorruptException, wrapped by ActiveRecord as
#   ActiveRecord::StatementInvalid.
#
# Layer 1 — degrade gracefully:
#   Solid Cache's upstream Failsafe only rescues a small, hardcoded list of
#   "transient" ActiveRecord errors. It does NOT rescue
#   ActiveRecord::StatementInvalid, so a read/write against a corrupt file
#   500'd the request (the error bubbled up through ActionView's `cache`
#   helper, see app/views/articles/_widgets.html.erb) even though a cache miss
#   would be a perfectly fine fallback. The prepended module below expands the
#   rescue list; rescued errors flow into the store's error_handler installed
#   at the bottom of this file.
#
# Layer 2 — heal the corruption (the root-cause fix):
#   Nothing ever repaired the file, so the error repeated forever and the cache
#   stayed dead until an operator deleted it by hand. Notably the background
#   expiry thread (Store::Expiry#expire_later → Entry.expire) is NOT wrapped in
#   Failsafe — it re-raised the corruption on every cache write, which is the
#   unhandled stack trace behind this error. So we:
#     * install an `error_handler` on the store — the single choke point that
#       both Failsafe and the expiry thread report through — which reports each
#       failure to Rails.error and detects corruption via the exception's
#       cause chain;
#     * on corruption, rebuild the database (flock-guarded across the processes
#       sharing the volume; a cache is disposable, so dropping it is safe);
#     * run a cheap `PRAGMA quick_check` at boot — before bin/docker-entrypoint's
#       `db:prepare` and before any traffic — so an already-corrupt file is
#       healed deterministically on the next deploy.
#
# This file is intentionally self-contained (the module is defined here rather
# than in lib/): the wiring below has to run via `after_initialize`, because
# Rails does not set up the autoloaders until after all initializers have run
# (Application::Finisher#setup_main_autoloader) — neither lib/ nor the gem's
# own models are referenceable in initializer file scope.
module SolidCacheFailsafeStatementInvalidExt
  def failsafe(method, returning: nil)
    yield
  rescue *SolidCache::Store::Failsafe::TRANSIENT_ACTIVE_RECORD_ERRORS,
         ActiveRecord::StatementInvalid => error
    error_handler&.call(method: method, exception: error, returning: returning)
    returning
  end
end

SolidCache::Store::Failsafe.prepend(SolidCacheFailsafeStatementInvalidExt)

# Self-healing for a corrupted Solid Cache SQLite database.
#
# Every path here only ever touches the `cache` database pool — never primary,
# cable or queue.
module SolidCacheRecovery
  # If the filesystem itself is broken, a rebuild attempt after every cache
  # write would be worse than the corruption. Failed attempts are throttled too.
  MIN_RECOVERY_INTERVAL = 60

  # SQLITE_CORRUPT ("database disk image is malformed") and SQLITE_NOTADB
  # ("file is not a database" — zeroed-out or truncated file) both mean the
  # file itself is unusable, as opposed to transient lock/timeout errors.
  RECOVERABLE_SQLITE_ERRORS = [SQLite3::CorruptException, SQLite3::NotADatabaseException].freeze

  # Installed as the Solid Cache store's `error_handler` at the bottom of this
  # file. Solid Cache routes every error it handles itself through this one
  # hook — both the Failsafe-wrapped request reads/writes and the unwrapped
  # background expiry thread — which makes it the single choke point where
  # corruption is detected and repaired.
  ERROR_HANDLER = ->(method:, returning:, exception:) do
    Rails.error&.report(exception, handled: true, severity: :warning,
                                    context: { cache_method: method, cache_store: "SolidCache" })
    Rails.logger&.error("SolidCacheStore: #{method} failed, returned #{returning.inspect}: " \
                       "#{exception.class}: #{exception.message}")

    SolidCacheRecovery.recover!(reason: "cache #{method} failed") if SolidCacheRecovery.corrupt_exception?(exception)
  end

  @recovery_mutex = Mutex.new
  @last_recovery_at = nil

  class << self
    def check_at_boot!
      return unless sqlite_cache?
      return unless File.exist?(db_path.to_s)

      healthy =
        begin
          cache_pool.with_connection { |connection| connection.select_value("PRAGMA quick_check(1)") } == "ok"
        rescue StandardError
          false # A file too broken to even run quick_check on is corrupt by definition.
        end

      recover!(reason: "quick_check failed at boot") unless healthy
    rescue StandardError => error
      report_recovery_failure(error, "boot integrity check")
    end

    def recover!(reason:)
      return unless sqlite_cache?
      return unless recovery_due?

      @recovery_mutex.synchronize do
        return unless recovery_due? # Re-check: another thread may have just repaired.

        with_repair_lock do |acquired|
          # Another process sharing the volume is already rebuilding; its
          # schema load is this process's repair too.
          next unless acquired

          rebuild_database!
          @last_recovery_at = monotonic_now
          Rails.logger&.info("[SolidCacheRecovery] rebuilt corrupt cache database at #{db_path} (#{reason})")
        end
      end
    rescue StandardError => error
      @last_recovery_at = monotonic_now
      report_recovery_failure(error, "cache database rebuild")
    end

    def corrupt_exception?(exception)
      while exception
        return true if RECOVERABLE_SQLITE_ERRORS.any? { |klass| exception.is_a?(klass) }
        exception = exception.cause
      end
      false
    end

    private
      def rebuild_database!
        pool = cache_pool
        pool.disconnect! # Connections may still hold the corrupt file's inode open.
        remove_database_files!
        load_schema_against_cache_pool!
      end

      def remove_database_files!
        [db_path, "#{db_path}-wal", "#{db_path}-shm", "#{db_path}-journal"].each do |file|
          File.delete(file) if File.exist?(file)
        end
      end

      # Recreates the schema by loading db/cache_schema.rb against the *cache*
      # pool. `ActiveRecord::Schema#define` resolves its connection through
      # `ActiveRecord::Tasks::DatabaseTasks.migration_class`, so that is pointed
      # at the cache model for the duration of the load — the same targeting
      # Rails' own `db:prepare` uses (see DatabaseTasks#with_temporary_pool),
      # but scoped to the cache model instead of clobbering ActiveRecord::Base.
      # Only migration/schema tooling reads that method, never request paths,
      # so the swap is safe at runtime.
      def load_schema_against_cache_pool!
        tasks = ActiveRecord::Tasks::DatabaseTasks
        target = schema_target
        tasks.define_singleton_method(:migration_class) { target }
        load schema_path.to_s
      ensure
        tasks.singleton_class.remove_method(:migration_class)
      end

      def with_repair_lock
        File.open("#{db_path}.recovery.lock", File::CREAT | File::RDWR) do |lock|
          # `flock` returns 0 when the lock is acquired and false when another
          # process holds it.
          yield lock.flock(File::LOCK_EX | File::LOCK_NB) == 0
        end
      end

      def recovery_due?
        @last_recovery_at.nil? || monotonic_now - @last_recovery_at >= MIN_RECOVERY_INTERVAL
      end

      def sqlite_cache?
        cache_db_config&.adapter == "sqlite3"
      rescue StandardError
        false
      end

      # Kept as separate methods so tests can point them at a scratch database
      # instead of stubbing SolidCache::Record itself.
      def cache_db_config
        SolidCache::Record.connection_db_config
      end

      def db_path
        cache_db_config.configuration_hash.fetch(:database)
      end

      def cache_pool
        SolidCache::Record.connection_pool
      end

      def schema_target
        SolidCache::Record
      end

      def schema_path
        Rails.root.join("db/cache_schema.rb")
      end

      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def report_recovery_failure(error, stage)
        Rails.error&.report(error, handled: true, severity: :error,
                                   context: { cache_store: "SolidCache", recovery_stage: stage })
        Rails.logger&.error("[SolidCacheRecovery] #{stage} failed: #{error.class}: #{error.message}")
      end
  end
end

# Rails.cache was already instantiated during bootstrap (see
# Rails::Application::Bootstrap#initialize_cache), but Solid Cache's models
# (SolidCache::Record and friends) only become autoloadable once the finishers
# have set the autoloaders up — so `after_initialize` is the earliest point
# where the live store can be wired and the cache database checked. This runs
# before bin/docker-entrypoint's `db:prepare` and before any traffic.
Rails.application.config.after_initialize do
  next unless Rails.cache.is_a?(SolidCache::Store)

  Rails.cache.instance_variable_set(:@error_handler, SolidCacheRecovery::ERROR_HANDLER)
  SolidCacheRecovery.check_at_boot!
end
