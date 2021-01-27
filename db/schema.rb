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

ActiveRecord::Schema.define(version: 2021_01_27_092037) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.string "action_option"
    t.string "target_type"
    t.bigint "target_id"
    t.string "user_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type", "target_type", "target_id", "user_type", "user_id"], name: "uk_action_target_user", unique: true
    t.index ["target_type", "target_id", "action_type"], name: "index_actions_on_target_type_and_target_id_and_action_type"
    t.index ["user_type", "user_id", "action_type"], name: "index_actions_on_user_type_and_user_id_and_action_type"
  end

  create_table "administrators", force: :cascade do |t|
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_administrators_on_name", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.string "message_type"
    t.text "content"
    t.string "state"
    t.datetime "delivered_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "articles", force: :cascade do |t|
    t.uuid "uuid"
    t.bigint "author_id"
    t.string "title"
    t.string "intro"
    t.text "content"
    t.uuid "asset_id", comment: "asset_id in Mixin Network"
    t.decimal "price", null: false
    t.decimal "revenue", default: "0.0"
    t.integer "orders_count", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.string "state"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "commenting_subscribers_count", default: 0
    t.integer "upvotes_count", default: 0
    t.integer "downvotes_count", default: 0
    t.integer "tags_count", default: 0
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["uuid"], name: "index_articles_on_uuid", unique: true
  end

  create_table "bonuses", force: :cascade do |t|
    t.bigint "user_id"
    t.string "title"
    t.text "description"
    t.string "state"
    t.string "asset_id"
    t.decimal "amount"
    t.uuid "trace_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["trace_id"], name: "index_bonuses_on_trace_id", unique: true
    t.index ["user_id"], name: "index_bonuses_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.string "content"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "upvotes_count", default: 0
    t.integer "downvotes_count", default: 0
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
  end

  create_table "mixin_messages", force: :cascade do |t|
    t.string "action"
    t.string "category"
    t.uuid "user_id"
    t.uuid "conversation_id"
    t.uuid "message_id"
    t.string "content", comment: "decrepted data"
    t.json "raw"
    t.datetime "processed_at"
    t.string "state"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id"], name: "index_mixin_messages_on_message_id", unique: true
  end

  create_table "mixin_network_snapshots", force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "trace_id"
    t.uuid "opponent_id"
    t.string "data"
    t.uuid "snapshot_id"
    t.decimal "amount"
    t.uuid "asset_id"
    t.datetime "transferred_at"
    t.json "raw"
    t.datetime "processed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["trace_id"], name: "index_mixin_network_snapshots_on_trace_id", unique: true
    t.index ["user_id"], name: "index_mixin_network_snapshots_on_user_id"
  end

  create_table "mixin_network_users", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.uuid "uuid"
    t.string "name"
    t.uuid "session_id"
    t.string "pin_token"
    t.json "raw"
    t.string "private_key"
    t.string "encrypted_pin"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["owner_type", "owner_id"], name: "index_mixin_network_users_on_owner_type_and_owner_id"
    t.index ["uuid"], name: "index_mixin_network_users_on_uuid", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.string "type", null: false
    t.jsonb "params"
    t.datetime "read_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "seller_id"
    t.bigint "buyer_id"
    t.string "item_type"
    t.bigint "item_id"
    t.uuid "trace_id"
    t.string "state"
    t.integer "order_type"
    t.decimal "total"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["item_type", "item_id"], name: "index_orders_on_item_type_and_item_id"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
  end

  create_table "payments", force: :cascade do |t|
    t.uuid "opponent_id"
    t.uuid "trace_id"
    t.uuid "snapshot_id"
    t.uuid "asset_id"
    t.decimal "amount"
    t.string "memo"
    t.string "state"
    t.json "raw"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["trace_id"], name: "index_payments_on_trace_id", unique: true
  end

  create_table "swap_orders", force: :cascade do |t|
    t.bigint "payment_id"
    t.uuid "trace_id"
    t.uuid "user_id"
    t.string "state"
    t.uuid "pay_asset_id", comment: "paid asset"
    t.uuid "fill_asset_id", comment: "swapped asset"
    t.decimal "funds", comment: "paid amount"
    t.decimal "amount", comment: "swapped amount"
    t.decimal "min_amount", comment: "minimum swapped amount"
    t.json "raw", comment: "raw order response"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["payment_id"], name: "index_swap_orders_on_payment_id"
    t.index ["trace_id"], name: "index_swap_orders_on_trace_id", unique: true
    t.index ["user_id"], name: "index_swap_orders_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.bigint "article_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["article_id"], name: "index_taggings_on_article_id"
    t.index ["tag_id", "article_id"], name: "index_taggings_on_tag_id_and_article_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "articles_count", default: 0
    t.integer "subscribers_count", default: 0
  end

  create_table "transfers", force: :cascade do |t|
    t.string "source_type"
    t.bigint "source_id"
    t.integer "transfer_type"
    t.decimal "amount"
    t.uuid "trace_id"
    t.uuid "asset_id"
    t.uuid "opponent_id"
    t.string "memo"
    t.datetime "processed_at"
    t.json "snapshot"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "wallet_id"
    t.integer "queue_priority", default: 0
    t.index ["source_type", "source_id"], name: "index_transfers_on_source_type_and_source_id"
    t.index ["trace_id"], name: "index_transfers_on_trace_id", unique: true
    t.index ["wallet_id"], name: "index_transfers_on_wallet_id"
  end

  create_table "user_authorizations", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "provider", comment: "third party auth provider"
    t.string "uid", comment: "third party user id"
    t.string "access_token"
    t.json "raw", comment: "third pary user info"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["provider", "uid"], name: "index_user_authorizations_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_authorizations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "avatar_url"
    t.string "mixin_id"
    t.uuid "mixin_uuid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "authoring_subscribers_count", default: 0
    t.integer "reading_subscribers_count", default: 0
    t.datetime "banned_at"
    t.jsonb "statistics", default: "{}"
    t.index ["mixin_id"], name: "index_users_on_mixin_id", unique: true
    t.index ["mixin_uuid"], name: "index_users_on_mixin_uuid", unique: true
    t.index ["statistics"], name: "index_users_on_statistics", using: :gin
  end

end
