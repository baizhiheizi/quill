# frozen_string_literal: true

class UpgradeSolidCacheEntries < ActiveRecord::Migration[7.2]
  def up
    # Solid Cache now lives in the SQLite cache DB (db/cache_migrate). The legacy
    # Postgres table cannot be upgraded in place without backfilling key_hash on
    # every row; drop it so deploys from older releases can proceed.
    drop_table :solid_cache_entries, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
