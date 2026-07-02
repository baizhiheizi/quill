# frozen_string_literal: true

# Removes the NFT plumbing tables that backed the (now-shut-down) Mixin
# collectibles / on-chain ERC-721 machinery. Part of the legacy cleanup
# tracked in #1790. `Collection` itself stays — it's still a paid-bundle
# product feature; only the NFT layer underneath it goes away.
class DropNftTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :collectings, if_exists: true
    drop_table :collectibles, if_exists: true
    drop_table :nft_collections, if_exists: true
    drop_table :non_fungible_outputs, if_exists: true
  end

  def down
    create_table :nft_collections do |t|
      t.uuid :uuid
      t.uuid :creator_id
      t.jsonb :raw

      t.timestamps
    end
    add_index :nft_collections, :uuid, unique: true

    create_table :collectibles do |t|
      t.string :identifier
      t.string :metahash
      t.string :name
      t.uuid :collection_id
      t.uuid :token_id
      t.jsonb :metadata
      t.string :state
      t.string :source_type
      t.bigint :source_id

      t.timestamps
    end
    add_index :collectibles, %i[collection_id identifier], unique: true
    add_index :collectibles, :metahash, unique: true
    add_index :collectibles, %i[source_type source_id], unique: true
    add_index :collectibles, :token_id, unique: true

    create_table :collectings do |t|
      t.bigint :collection_id
      t.bigint :nft_collection_id

      t.timestamps
    end
    add_index :collectings, %i[collection_id nft_collection_id], unique: true

    create_table :non_fungible_outputs do |t|
      t.uuid :user_id
      t.uuid :token_id
      t.uuid :output_id
      t.string :state
      t.jsonb :raw

      t.timestamps
    end
    add_index :non_fungible_outputs, :output_id, unique: true
    add_index :non_fungible_outputs, :token_id
    add_index :non_fungible_outputs, :user_id
  end
end
