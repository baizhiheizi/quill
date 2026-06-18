# frozen_string_literal: true

class AddArticlesCountAndCommentsCountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :articles_count, :integer, default: 0, null: false
    add_column :users, :comments_count, :integer, default: 0, null: false

    # Backfill from existing data. Counter caches are added now; this
    # migration is the only place that knows the historical COUNT, so the
    # backfill lives here rather than relying on Rails' reset_counters at
    # boot. `users.id IS NOT NULL` is implied by the foreign key.
    execute <<~SQL.squish
      UPDATE users
         SET articles_count = COALESCE(sub.cnt, 0)
        FROM (SELECT author_id, COUNT(*) AS cnt
                FROM articles
               WHERE author_id IS NOT NULL
            GROUP BY author_id) AS sub
       WHERE users.id = sub.author_id
    SQL

    execute <<~SQL.squish
      UPDATE users
         SET comments_count = COALESCE(sub.cnt, 0)
        FROM (SELECT author_id, COUNT(*) AS cnt
                FROM comments
               WHERE author_id IS NOT NULL
            GROUP BY author_id) AS sub
       WHERE users.id = sub.author_id
    SQL
  end

  def down
    remove_column :users, :comments_count
    remove_column :users, :articles_count
  end
end
