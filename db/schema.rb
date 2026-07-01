# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_01_102748) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "access_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at", precision: nil
    t.jsonb "last_request"
    t.string "memo"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.uuid "value"
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
    t.index ["value"], name: "index_access_tokens_on_value", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "actions", force: :cascade do |t|
    t.string "action_option"
    t.string "action_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id"
    t.string "user_type"
    t.index ["action_type", "target_type", "target_id", "user_type", "user_id"], name: "uk_action_target_user", unique: true
    t.index ["target_type", "target_id", "action_type"], name: "index_actions_on_target_type_and_target_id_and_action_type"
    t.index ["user_type", "user_id", "action_type"], name: "index_actions_on_user_type_and_user_id_and_action_type"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "administrators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_administrators_on_name", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "delivered_at", precision: nil
    t.string "message_type"
    t.string "state"
    t.datetime "updated_at", null: false
  end

  create_table "article_snapshots", force: :cascade do |t|
    t.uuid "article_uuid"
    t.datetime "created_at", null: false
    t.json "raw"
    t.datetime "updated_at", null: false
    t.index ["article_uuid"], name: "index_article_snapshots_on_article_uuid"
  end

  create_table "articles", force: :cascade do |t|
    t.uuid "asset_id", comment: "asset_id in Mixin Network"
    t.bigint "author_id"
    t.float "author_revenue_ratio", default: 0.5
    t.uuid "collection_id"
    t.float "collection_revenue_ratio", default: 0.0
    t.integer "commenting_subscribers_count", default: 0
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "downvotes_count", default: 0
    t.float "free_content_ratio", default: 0.1
    t.string "intro"
    t.text "legacy_markdown_content"
    t.string "locale"
    t.integer "orders_count", default: 0, null: false
    t.float "platform_revenue_ratio", default: 0.1
    t.decimal "price", null: false
    t.datetime "published_at", precision: nil
    t.float "readers_revenue_ratio", default: 0.4
    t.float "references_revenue_ratio", default: 0.0
    t.decimal "revenue_btc", default: "0.0"
    t.decimal "revenue_usd", default: "0.0"
    t.string "source"
    t.string "state"
    t.integer "tags_count", default: 0
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "upvotes_count", default: 0
    t.uuid "uuid"
    t.index ["asset_id"], name: "index_articles_on_asset_id"
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["collection_id"], name: "index_articles_on_collection_id"
    t.index ["uuid"], name: "index_articles_on_uuid", unique: true
  end

  create_table "bonuses", force: :cascade do |t|
    t.decimal "amount"
    t.string "asset_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "state"
    t.string "title"
    t.uuid "trace_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["trace_id"], name: "index_bonuses_on_trace_id", unique: true
    t.index ["user_id"], name: "index_bonuses_on_user_id"
  end

  create_table "citer_references", force: :cascade do |t|
    t.bigint "citer_id"
    t.string "citer_type"
    t.datetime "created_at", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.float "revenue_ratio", null: false
    t.datetime "updated_at", null: false
    t.index ["citer_type", "citer_id"], name: "index_citer_references_on_citer"
    t.index ["reference_type", "reference_id"], name: "index_citer_references_on_reference"
  end

  create_table "collectibles", force: :cascade do |t|
    t.uuid "collection_id"
    t.datetime "created_at", null: false
    t.string "identifier"
    t.jsonb "metadata"
    t.string "metahash"
    t.string "name"
    t.bigint "source_id"
    t.string "source_type"
    t.string "state"
    t.uuid "token_id"
    t.datetime "updated_at", null: false
    t.index ["collection_id", "identifier"], name: "index_collectibles_on_collection_id_and_identifier", unique: true
    t.index ["metahash"], name: "index_collectibles_on_metahash", unique: true
    t.index ["source_type", "source_id"], name: "index_collectibles_on_source_type_and_source_id", unique: true
    t.index ["token_id"], name: "index_collectibles_on_token_id", unique: true
  end

  create_table "collectings", force: :cascade do |t|
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.bigint "nft_collection_id"
    t.datetime "updated_at", null: false
    t.index ["collection_id", "nft_collection_id"], name: "index_collectings_on_collection_id_and_nft_collection_id", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.uuid "asset_id"
    t.uuid "author_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "orders_count", default: 0
    t.float "platform_revenue_ratio", default: 0.1
    t.decimal "price"
    t.float "revenue_ratio", default: 0.2
    t.string "state"
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.uuid "uuid"
    t.index ["author_id"], name: "index_collections_on_author_id"
    t.index ["uuid"], name: "index_collections_on_uuid", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "author_id"
    t.bigint "commentable_id"
    t.string "commentable_type"
    t.integer "comments_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "downvotes_count", default: 0
    t.string "legacy_markdown_content"
    t.bigint "quote_comment_id"
    t.datetime "updated_at", null: false
    t.integer "upvotes_count", default: 0
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["quote_comment_id"], name: "index_comments_on_quote_comment_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.uuid "asset_id"
    t.uuid "chain_id"
    t.datetime "created_at", null: false
    t.string "mvm_contract_address"
    t.decimal "price_btc"
    t.decimal "price_usd"
    t.jsonb "raw"
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_currencies_on_asset_id", unique: true
  end

  create_table "exception_tracks", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil, null: false
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "impressions", force: :cascade do |t|
    t.string "action_name"
    t.string "controller_name"
    t.datetime "created_at", null: false
    t.integer "impressionable_id"
    t.string "impressionable_type"
    t.string "ip_address"
    t.text "message"
    t.text "params"
    t.text "referrer"
    t.string "request_hash"
    t.string "session_hash"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "view_name"
    t.index ["controller_name", "action_name", "ip_address"], name: "controlleraction_ip_index"
    t.index ["controller_name", "action_name", "request_hash"], name: "controlleraction_request_index"
    t.index ["controller_name", "action_name", "session_hash"], name: "controlleraction_session_index"
    t.index ["impressionable_type", "impressionable_id", "ip_address"], name: "poly_ip_index"
    t.index ["impressionable_type", "impressionable_id", "params"], name: "poly_params_request_index"
    t.index ["impressionable_type", "impressionable_id", "request_hash"], name: "poly_request_index"
    t.index ["impressionable_type", "impressionable_id", "session_hash"], name: "poly_session_index"
    t.index ["impressionable_type", "message", "impressionable_id"], name: "impressionable_type_message_index"
    t.index ["user_id"], name: "index_impressions_on_user_id"
  end

  create_table "mixin_messages", force: :cascade do |t|
    t.string "action"
    t.string "category"
    t.string "content", comment: "decrepted data"
    t.uuid "conversation_id"
    t.datetime "created_at", null: false
    t.uuid "message_id"
    t.datetime "processed_at", precision: nil
    t.json "raw"
    t.string "state"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["message_id"], name: "index_mixin_messages_on_message_id", unique: true
  end

  create_table "mixin_network_snapshots", force: :cascade do |t|
    t.decimal "amount"
    t.uuid "asset_id"
    t.datetime "created_at", null: false
    t.string "data"
    t.uuid "opponent_id"
    t.datetime "processed_at", precision: nil
    t.uuid "snapshot_id"
    t.uuid "trace_id"
    t.datetime "transferred_at", precision: nil
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["created_at"], name: "index_mixin_network_snapshots_on_created_at"
    t.index ["processed_at"], name: "index_mixin_network_snapshots_on_processed_at"
    t.index ["snapshot_id"], name: "index_mixin_network_snapshots_on_snapshot_id", unique: true
    t.index ["trace_id"], name: "index_mixin_network_snapshots_on_trace_id"
    t.index ["user_id"], name: "index_mixin_network_snapshots_on_user_id"
  end

  create_table "mixin_network_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_pin"
    t.string "name"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "pin"
    t.string "pin_token"
    t.string "private_key"
    t.json "raw"
    t.uuid "session_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.uuid "uuid"
    t.index ["owner_type", "owner_id"], name: "index_mixin_network_users_on_owner_type_and_owner_id"
    t.index ["uuid"], name: "index_mixin_network_users_on_uuid", unique: true
  end

  create_table "nft_collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "creator_id"
    t.jsonb "raw"
    t.datetime "updated_at", null: false
    t.uuid "uuid"
    t.index ["uuid"], name: "index_nft_collections_on_uuid", unique: true
  end

  create_table "non_fungible_outputs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "output_id"
    t.jsonb "raw"
    t.string "state"
    t.uuid "token_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["output_id"], name: "index_non_fungible_outputs_on_output_id", unique: true
    t.index ["token_id"], name: "index_non_fungible_outputs_on_token_id"
    t.index ["user_id"], name: "index_non_fungible_outputs_on_user_id"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.jsonb "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.jsonb "article_bought", default: "{}"
    t.jsonb "article_published", default: "{}"
    t.jsonb "article_rewarded", default: "{}"
    t.jsonb "comment_created", default: "{}"
    t.datetime "created_at", null: false
    t.jsonb "tagging_created", default: "{}"
    t.jsonb "transfer_processed", default: "{}"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.jsonb "webhook", default: "{}"
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.uuid "asset_id"
    t.bigint "buyer_id"
    t.integer "citer_id"
    t.string "citer_type"
    t.datetime "created_at", null: false
    t.bigint "item_id"
    t.string "item_type"
    t.integer "order_type"
    t.bigint "seller_id"
    t.string "state"
    t.decimal "total"
    t.uuid "trace_id"
    t.datetime "updated_at", null: false
    t.decimal "value_btc"
    t.decimal "value_usd"
    t.index ["asset_id"], name: "index_orders_on_asset_id"
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["citer_type", "citer_id"], name: "index_orders_on_citer_type_and_citer_id"
    t.index ["item_type", "item_id"], name: "index_orders_on_item_type_and_item_id"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount"
    t.uuid "asset_id"
    t.datetime "created_at", null: false
    t.string "memo"
    t.uuid "opponent_id"
    t.uuid "payer_id"
    t.json "raw"
    t.uuid "snapshot_id"
    t.string "state"
    t.uuid "trace_id"
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_payments_on_asset_id"
    t.index ["opponent_id"], name: "index_payments_on_opponent_id"
    t.index ["payer_id"], name: "index_payments_on_payer_id"
    t.index ["trace_id"], name: "index_payments_on_trace_id", unique: true
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.text "user"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pre_orders", force: :cascade do |t|
    t.decimal "amount"
    t.uuid "asset_id"
    t.datetime "created_at", null: false
    t.uuid "follow_id"
    t.bigint "item_id"
    t.string "item_type"
    t.string "memo"
    t.string "order_type"
    t.uuid "payee_id"
    t.uuid "payer_id"
    t.string "state"
    t.uuid "trace_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["item_type", "item_id"], name: "index_pre_orders_on_item"
    t.index ["payee_id"], name: "index_pre_orders_on_payee_id"
    t.index ["payer_id"], name: "index_pre_orders_on_payer_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "info"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.uuid "uuid"
    t.index ["user_id"], name: "index_sessions_on_user_id"
    t.index ["uuid"], name: "index_sessions_on_uuid", unique: true
  end

  create_table "statistics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.datetime "datetime", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
  end

  create_table "swap_orders", force: :cascade do |t|
    t.decimal "amount", comment: "swapped amount"
    t.datetime "created_at", null: false
    t.uuid "fill_asset_id", comment: "swapped asset"
    t.decimal "funds", comment: "paid amount"
    t.decimal "min_amount", comment: "minimum swapped amount"
    t.uuid "pay_asset_id", comment: "paid asset"
    t.bigint "payment_id"
    t.json "raw", comment: "raw order response"
    t.string "state"
    t.uuid "trace_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["payment_id"], name: "index_swap_orders_on_payment_id"
    t.index ["trace_id"], name: "index_swap_orders_on_trace_id", unique: true
    t.index ["user_id"], name: "index_swap_orders_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "article_id"
    t.datetime "created_at", null: false
    t.bigint "tag_id"
    t.datetime "updated_at", null: false
    t.index ["tag_id", "article_id"], name: "index_taggings_on_tag_id_and_article_id", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.integer "articles_count", default: 0
    t.datetime "created_at", null: false
    t.string "locale"
    t.string "name"
    t.integer "subscribers_count", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "transfers", force: :cascade do |t|
    t.decimal "amount"
    t.uuid "asset_id"
    t.datetime "created_at", null: false
    t.string "memo"
    t.uuid "opponent_id"
    t.json "opponent_multisig", default: {}
    t.datetime "processed_at", precision: nil
    t.integer "queue_priority", default: 0
    t.datetime "retry_at"
    t.json "snapshot"
    t.bigint "source_id"
    t.string "source_type"
    t.uuid "trace_id"
    t.integer "transfer_type"
    t.datetime "updated_at", null: false
    t.uuid "wallet_id"
    t.index ["asset_id"], name: "index_transfers_on_asset_id"
    t.index ["created_at"], name: "index_transfers_on_created_at"
    t.index ["opponent_id"], name: "index_transfers_on_opponent_id"
    t.index ["processed_at"], name: "index_transfers_on_processed_at"
    t.index ["source_type", "source_id"], name: "index_transfers_on_source_type_and_source_id"
    t.index ["trace_id"], name: "index_transfers_on_trace_id", unique: true
    t.index ["transfer_type"], name: "index_transfers_on_transfer_type"
    t.index ["wallet_id"], name: "index_transfers_on_wallet_id"
  end

  create_table "user_authorizations", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.integer "provider", comment: "third party auth provider"
    t.string "public_key"
    t.json "raw", comment: "third pary user info"
    t.string "uid", comment: "third party user id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["provider", "uid"], name: "index_user_authorizations_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_authorizations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.integer "authoring_subscribers_count", default: 0
    t.text "biography"
    t.datetime "blocked_at"
    t.integer "blocking_count", default: 0
    t.integer "blocks_count", default: 0
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "email_verified_at"
    t.string "locale"
    t.string "mixin_id"
    t.uuid "mixin_uuid"
    t.string "name"
    t.integer "reading_subscribers_count", default: 0
    t.integer "subscribers_count", default: 0
    t.integer "subscribing_count", default: 0
    t.string "uid"
    t.datetime "updated_at", null: false
    t.datetime "validated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["mixin_id"], name: "index_users_on_mixin_id"
    t.index ["mixin_uuid"], name: "index_users_on_mixin_uuid", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
