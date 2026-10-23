# frozen_string_literal: true

# Two indexes the article surfaces were missing.
#
# `articles.state` was never indexed, so every "published articles" query
# seq-scanned the table. That query is on the hot path in five places:
# `Article.only_published` (the web feed, the JSON API index, the API's
# per-author articles), `Article.only_published.count` and
# `.sum(:revenue_usd)` (both on the home page), and
# `Admin::ArticlesController#index` (`articles.where(state: @state)`).
#
# `published_at` is the second column because `ORDERS[:recent]` — the
# "lately" and "subscribed" feed sorts — orders by `published_at DESC`, and
# `articles` had no index on it at all. With `(state, published_at)` the
# "lately" feed becomes an index scan that returns rows already in order,
# so Postgres neither sorts the published set nor reads the whole table.
#
# `taggings.article_id` had no index either. The only index was
# `(tag_id, article_id)`, which puts `article_id` in the non-leading
# position, so it cannot answer a lookup by `article_id` alone. Every
# article list preloads `:tags` through that join
# (`Article.with_associations` -> `includes(:tags)`), which issues
# `SELECT taggings.* WHERE taggings.article_id IN (...)` — a seq scan of
# `taggings` on every feed page.
class AddMissingFeedIndexes < ActiveRecord::Migration[8.1]
  def up
    add_index :articles, %i[state published_at], name: "index_articles_on_state_and_published_at"
    add_index :taggings, :article_id, name: "index_taggings_on_article_id"

    # Postgres collects per-index statistics during ANALYZE. An index added
    # to an already-populated table has none, and the planner will not use
    # it for an ordered scan until an ANALYZE has run — without index
    # statistics it cannot estimate how many rows the scan returns, so it
    # falls back to the seq scan it already knows. Without these two lines
    # the "lately" feed keeps sorting the whole published set until the next
    # autovacuum happens to fire.
    execute "ANALYZE articles"
    execute "ANALYZE taggings"
  end

  def down
    remove_index :taggings, name: "index_taggings_on_article_id"
    remove_index :articles, name: "index_articles_on_state_and_published_at"

    execute "ANALYZE articles"
    execute "ANALYZE taggings"
  end
end
