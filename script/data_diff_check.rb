# frozen_string_literal: true

# Cross-Locale Article Visibility — Pre/Post-Deploy Data Integrity Verification
# (specs/001-unified-article-translations, US6 / FR-006 / SC-005 / SC-008).
#
# Usage:
#   bin/rails runner tmp/data_diff_check.rb > /tmp/data_$(date +%Y%m%d_%H%M%S).yaml
#   # ... deploy ...
#   bin/rails runner tmp/data_diff_check.rb > /tmp/data_$(date +%Y%m%d_%H%M%S).yaml
#   diff /tmp/data_before.yaml /tmp/data_after.yaml
#
# Expected: zero differences. The Cross-Locale Article Visibility feature is
# a behavior change (visitor-facing locale filter removed) — it does NOT
# touch any row in `articles`, `orders`, `comments`, `article_snapshots`,
# `transfers`, or related tables. This script dumps the union of every
# relevant row's identifying fields and stable content columns to YAML so a
# `diff` between pre- and post-deploy dumps is byte-stable.

require "yaml"

def dump_rows(label, relation, columns)
  rows = relation.pluck(*columns).map { |tuple| Hash[columns.zip(tuple)] }
  { label => rows.sort_by { |r| r[columns.first] } }
end

# Choose the primary-key column for each table — most are `id`, but
# `articles` uses `uuid` for human-readable ordering in the diff output.
dumps = []

dumps << dump_rows("articles", Article, %i[uuid title intro locale state published_at price])
dumps << dump_rows("orders", Order, %i[id item_type item_id value_usd])
dumps << dump_rows("comments", Comment, %i[id commentable_type commentable_id author_id])
dumps << dump_rows("article_snapshots", ArticleSnapshot, %i[id article_uuid raw])
dumps << dump_rows("transfers", Transfer, %i[id wallet_id amount transfer_type processed_at])

# A single concatenated dump — stable across runs because each sub-array is
# sorted by its primary key.
yaml_output = dumps.reduce({}) { |acc, h| acc.merge(h) }.to_yaml
puts yaml_output

# Also print a single SHA256 checksum of the dump so a quick comparison is
# possible without `diff`:
require "digest"
puts "# checksum: #{Digest::SHA256.hexdigest(yaml_output)}"
