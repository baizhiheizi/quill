# frozen_string_literal: true

require "test_helper"

# Two indexes the article surfaces depended on but the schema did not have.
#
# `articles.state` was unindexed, so `Article.only_published` — the feed, the
# JSON API index, the home page's article count and revenue sum, and the
# admin articles index — seq-scanned the table every time. `published_at` was
# unindexed too, so the "lately" feed sort (`ORDER BY published_at DESC`)
# sorted the whole published set before taking 50 rows.
#
# `taggings.article_id` was unindexed. The only index on the table was
# `(tag_id, article_id)`, which cannot answer a lookup by `article_id`
# alone, so the `:tags` preload that every article list performs
# (`Article.with_associations` -> `includes(:tags)`) seq-scanned `taggings`.
#
# The indexes are invisible to the models, so nothing fails when one goes
# away — the feed just gets slower. This test is the guard.
class FeedIndexesTest < ActiveSupport::TestCase
  test "articles is indexed on state and published_at" do
    index = index_for(:articles, "index_articles_on_state_and_published_at")

    assert_not_nil index, "articles lost its (state, published_at) index"
    assert_equal %w[state published_at], index.columns,
                 "published_at must come second so the index can serve ORDER BY published_at DESC"
  end

  test "taggings is indexed on article_id" do
    index = index_for(:taggings, "index_taggings_on_article_id")

    assert_not_nil index, "taggings lost its article_id index"
    assert_equal %w[article_id], index.columns
  end

  private

  def index_for(table, name)
    ActiveRecord::Base.connection.indexes(table).find { |index| index.name == name }
  end
end
