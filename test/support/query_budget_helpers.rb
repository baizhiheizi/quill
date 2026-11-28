# frozen_string_literal: true

# Helpers for pinning how much SQL a request is allowed to issue.
#
# The surfaces that render `shared/_avatar` per row used to pay one SELECT
# per table of the avatar chain per row. The budget helpers exist to make
# that shape observable from a test: capture the SQL a request emits, then
# count the queries a given table was asked for.
module QueryBudgetHelpers
  # The tables the avatar chain (`User::AVATAR_PRELOADS`) touches: the
  # attachment row, its blob and variant records, and the user's
  # authorization. `shared/_avatar` reads `avatar.attached?`,
  # `avatar.variant(:thumb).processed.key` and `authorization.raw`, so a
  # surface that renders it per row without the preload chain pays one
  # SELECT per table per row.
  AVATAR_CHAIN_TABLES = [
    "user_authorizations",
    "active_storage_attachments",
    "active_storage_blobs",
    "active_storage_variant_records"
  ].freeze

  # Captures the SQL emitted while the block runs (SCHEMA noise excluded).
  def capture_sql
    queries = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end

  # How many of the captured queries hit the avatar chain.
  def avatar_chain_query_count(queries)
    queries.count { |q| AVATAR_CHAIN_TABLES.any? { |table| q.include?(%(FROM "#{table}")) } }
  end
end
