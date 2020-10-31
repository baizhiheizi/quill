# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_31_222811) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_administrators_on_name", unique: true
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
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["uuid"], name: "index_articles_on_uuid", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.string "content"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.index ["source_type", "source_id"], name: "index_transfers_on_source_type_and_source_id"
    t.index ["trace_id"], name: "index_transfers_on_trace_id", unique: true
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
    t.index ["mixin_id"], name: "index_users_on_mixin_id", unique: true
    t.index ["mixin_uuid"], name: "index_users_on_mixin_uuid", unique: true
  end

end
