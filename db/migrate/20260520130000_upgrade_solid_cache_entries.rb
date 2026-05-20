# frozen_string_literal: true

class UpgradeSolidCacheEntries < ActiveRecord::Migration[7.2]
  def up
    change_table :solid_cache_entries, bulk: true do |t|
      t.integer :key_hash, limit: 8, null: false, default: 0
      t.integer :byte_size, limit: 4, null: false, default: 0
    end

    change_column_default :solid_cache_entries, :key_hash, from: 0, to: nil
    change_column_default :solid_cache_entries, :byte_size, from: 0, to: nil

    remove_index :solid_cache_entries, :key
    add_index :solid_cache_entries, :byte_size
    add_index :solid_cache_entries, %i[key_hash byte_size]
    add_index :solid_cache_entries, :key_hash, unique: true
  end

  def down
    remove_index :solid_cache_entries, :key_hash
    remove_index :solid_cache_entries, %i[key_hash byte_size]
    remove_index :solid_cache_entries, :byte_size
    add_index :solid_cache_entries, :key, unique: true

    change_table :solid_cache_entries, bulk: true do |t|
      t.remove :key_hash
      t.remove :byte_size
    end
  end
end
