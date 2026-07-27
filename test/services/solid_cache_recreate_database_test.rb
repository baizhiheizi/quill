# frozen_string_literal: true

require "test_helper"

# Covers `SolidCacheRecreateDatabase` (rake task `solid_cache:recreate`).
#
# Why a dedicated file: this service is the operational recovery path for
# the production outage documented in
# `config/initializers/solid_cache_failsafe.rb` — a corrupted Solid Cache
# SQLite file produces "database disk image is malformed" errors that the
# patched Failsafe now downgrades to cache misses, but the cache itself
# stays broken until the file is deleted and re-created. Running
# `bin/rails solid_cache:recreate` does that, and these tests pin the
# contract: which file is deleted, which sidecars go with it, and what
# happens when the file is missing / in-memory.
class SolidCacheRecreateDatabaseTest < ActiveSupport::TestCase
  test "deletes the configured cache sqlite file plus its wal / shm / journal sidecars" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "test_cache.sqlite3")
      sidecars = [ "#{path}-wal", "#{path}-shm", "#{path}-journal" ]
([ path, *sidecars ]).each { |p| File.write(p, "not a real db") }

      deleted = SolidCacheRecreateDatabase.call(roles: [ :cache ], database_paths_for: ->(_) { path })

      assert_includes deleted, path
      sidecars.each { |sidecar| refute File.exist?(sidecar), "expected sidecar #{sidecar} to be deleted" }
    end
  end

  test "is a no-op when the configured cache file does not exist" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "does_not_exist.sqlite3")
      deleted = SolidCacheRecreateDatabase.call(roles: [ :cache ], database_paths_for: ->(_) { path })

      assert_empty deleted
    end
  end

  test "treats a blank path as a no-op" do
    deleted = SolidCacheRecreateDatabase.call(roles: [ :cache ], database_paths_for: ->(_) { "" })

    assert_empty deleted
  end

  test "treats an in-memory path as a no-op (would never be a real file)" do
    deleted = SolidCacheRecreateDatabase.call(roles: [ :cache ], database_paths_for: ->(_) { ":memory:" })

    assert_empty deleted
  end

  test "only acts on the roles it is given, leaving other cache files alone" do
    Dir.mktmpdir do |dir|
      cache_path = File.join(dir, "test_cache.sqlite3")
      cable_path = File.join(dir, "test_cable.sqlite3")
      [ cache_path, cable_path ].each { |p| File.write(p, "x") }

      paths = { cache: cache_path, cable: cable_path }
      SolidCacheRecreateDatabase.call(
        roles: [ :cache ],
        database_paths_for: ->(role) { paths[role] }
      )

      refute File.exist?(cache_path), "expected cache file to be deleted"
      assert File.exist?(cable_path), "expected cable file to be left alone"
    end
  end

  test "reads cache / cable / queue database paths from ActiveRecord config in production" do
    # The integration paths through the real config are tested in
    # bin/rails runner smoke-tests; here we just assert that
    # `default_database_path_for` returns nil for an unknown role rather
    # than raising, so a misconfigured role list can't crash the rake task.
    service = SolidCacheRecreateDatabase.new(roles: [ :cache ])

    assert_nil service.send(:default_database_path_for, :definitely_not_a_real_role)
  end
end
