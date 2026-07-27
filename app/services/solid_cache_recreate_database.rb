# frozen_string_literal: true

# Recreates the Solid Cache SQLite database file.
#
# Why this exists:
#   Solid Cache's cache, cable, and queue databases are stored as SQLite
#   files in storage/. When the container is killed mid-write (SIGKILL
#   during a deploy, OOM, host reboot, etc.) those files can end up in a
#   "database disk image is malformed" state. The Failsafe initializer
#   (see config/initializers/solid_cache_failsafe.rb) keeps the app
#   serving by treating corruption as a cache miss, but the cache stays
#   broken until the file is deleted and re-created.
#
# What this does:
#   - Closes any open ActiveRecord connections pointing at the cache DB.
#   - Deletes the SQLite file plus its -wal / -shm sidecars.
#   - Lets Solid Cache re-create the schema on next access via db:prepare
#     semantics (PRAGMA / ActiveRecord migrations on first connect).
#
# Usage:
#   bin/rails solid_cache:recreate
#
# WARNING: this wipes every cached entry (fragment caches, hot tags,
# platform stats, etc.). The next request that needs a cache entry will
# be a cache miss; no other data is touched.
class SolidCacheRecreateDatabase
  DEFAULT_ROLES = %i[cache cable queue].freeze

  def self.call(...)
    new(...).call
  end

  # +database_paths_for+ lets callers (notably tests) override the source of
  # truth. In production it defaults to `ActiveRecord::Base.configurations`,
  # but a test can pass a proc or hash so it doesn't have to mutate the
  # global DatabaseConfigurations object.
  def initialize(roles: DEFAULT_ROLES, database_paths_for: nil, logger: Rails.logger)
    @roles = Array(roles)
    @database_paths_for = database_paths_for || method(:default_database_path_for)
    @logger = logger
  end

  def call
    deleted_paths = []
    @roles.each do |role|
      path = @database_paths_for.call(role)
      next if path.nil?
      next unless File.exist?(path)

      close_pool_for(role)
      delete_with_sidecars(path) { |deleted| deleted_paths << deleted }
    end

    if deleted_paths.empty?
      @logger&.info("[SolidCache] No cache database files to recreate (checked: #{@roles.inspect})")
    else
      @logger&.info("[SolidCache] Recreated cache database files: #{deleted_paths.join(', ')}")
    end

    deleted_paths
  end

  private
    def default_database_path_for(role)
      config = ActiveRecord::Base.configurations.find_db_config(role.to_s)
      return nil if config.nil?

      db = config.database
      # Reject in-memory and blank values so we never try to delete ":memory:" or "".
      return nil if db.blank? || db == ":memory:"

      db
    end

    def close_pool_for(role)
      pool = ActiveRecord::Base.connection_handler.connection_pool_list(role)
      pool.disconnect! if pool.respond_to?(:disconnect!)
    rescue StandardError => e
      @logger&.warn("[SolidCache] Failed to close connections for #{role}: #{e.class}: #{e.message}")
    end

    def delete_with_sidecars(path)
      sidecars = [ "#{path}-wal", "#{path}-shm", "#{path}-journal" ]
      [ path, *sidecars ].each do |candidate|
        if File.exist?(candidate)
          File.delete(candidate)
          yield candidate
        end
      end
    end
end
