# frozen_string_literal: true

require "test_helper"

class ArticleVisibilityTest < ActiveSupport::TestCase
  test "for returns the base scope untouched for a nil viewer" do
    queries = capture_queries { @articles = ArticleVisibility.for(nil).to_a }

    assert_includes @articles.map(&:uuid), articles(:published_paid).uuid
    assert_empty queries.select { |q| q.include?('FROM "actions"') },
      "expected no actions query when the viewer is nil"
  end

  test "for hides authors the viewer blocked" do
    users(:reader_one).block_user(users(:author))

    articles = ArticleVisibility.for(users(:reader_one)).to_a

    assert_not_includes articles.map(&:author_id), users(:author).id
    assert_includes articles.map(&:uuid), articles(:published_zh).uuid
  end

  test "for hides authors who blocked the viewer" do
    users(:author_zh).block_user(users(:reader_one))

    articles = ArticleVisibility.for(users(:reader_one)).to_a

    assert_not_includes articles.map(&:uuid), articles(:published_zh).uuid
    assert_includes articles.map(&:uuid), articles(:published_paid).uuid
  end

  test "for never hides the viewer's own articles, even when someone blocked them" do
    users(:author_zh).block_user(users(:author))

    articles = ArticleVisibility.for(users(:author)).to_a

    assert_includes articles.map(&:uuid), articles(:published_paid).uuid,
      "expected the viewer's own articles to survive the blocker predicate"
    assert_not_includes articles.map(&:uuid), articles(:published_zh).uuid
  end

  test "for skips the block rule when asked" do
    users(:reader_one).block_user(users(:author))

    articles = ArticleVisibility.for(users(:reader_one), hide_blocked_authors: false).to_a

    assert_includes articles.map(&:uuid), articles(:published_paid).uuid
  end

  test "for keeps the block rule out of the SQL for a nil viewer" do
    queries = capture_queries { ArticleVisibility.for(nil).to_a }

    main = queries.find { |q| q.include?('FROM "articles"') }
    assert_no_match(/NOT\s+IN\s*\(SELECT/i, main,
      "expected no block predicate for a nil viewer, got: #{main}")
  end

  test "for inlines both block directions as SQL subqueries" do
    users(:reader_one).block_user(users(:author))
    users(:author_zh).block_user(users(:reader_one))

    queries = capture_queries { ArticleVisibility.for(users(:reader_one)).to_a }

    main = queries.find { |q| q.include?('FROM "articles"') }
    assert_operator main.scan(/NOT\s+IN\s*\(SELECT/i).size, :>=, 2,
      "expected both block directions inlined as SQL subqueries, got: #{main}"
  end

  test "authors hides blocked authors in both directions and the viewer themself" do
    base = User.where(id: [ users(:author).id, users(:author_zh).id, users(:reader_one).id ])
    users(:reader_one).block_user(users(:author))
    users(:author_zh).block_user(users(:reader_one))

    visible = ArticleVisibility.authors(users(:reader_one), base:).map(&:id)

    assert_not_includes visible, users(:author).id, "expected authors the viewer blocked to be hidden"
    assert_not_includes visible, users(:author_zh).id, "expected authors who blocked the viewer to be hidden"
    assert_not_includes visible, users(:reader_one).id, "expected the viewer to be excluded"
  end

  test "authors is a no-op for a nil viewer" do
    queries = capture_queries { ArticleVisibility.authors(nil, base: User.active).to_a }

    assert_empty queries.select { |q| q.include?('FROM "actions"') },
      "expected no actions query when the viewer is nil"
  end

  test "cap strips and truncates to the query length limit" do
    long_query = "a" * (ArticleVisibility::QUERY_LENGTH_LIMIT + 50)

    assert_equal "a" * ArticleVisibility::QUERY_LENGTH_LIMIT, ArticleVisibility.cap("  #{long_query}  ")
    assert_equal "", ArticleVisibility.cap(nil)
  end

  test "cap_each splits, strips and truncates each comma-separated term" do
    assert_equal %w[a b c], ArticleVisibility.cap_each(" a , b , c , ")
    assert_empty ArticleVisibility.cap_each(" , , ")
    assert_empty ArticleVisibility.cap_each(nil)
  end

  test "cap_each spends the length budget on the param before splitting it" do
    long_term = "b" * (ArticleVisibility::QUERY_LENGTH_LIMIT + 10)

    # The JSON API's existing contract: the whole param is capped up front, so
    # an oversized first term consumes the budget and anything after it is
    # dropped rather than silently searched for.
    assert_equal [ "b" * ArticleVisibility::QUERY_LENGTH_LIMIT ], ArticleVisibility.cap_each(long_term)
  end

  test "searching matches title, intro, author and tags case-insensitively" do
    %i[title intro author tags].zip(
      [ "free article", "FREE ARTICLE INTRO", "test author", "WEB3" ]
    ).each do |field, term|
      @articles = ArticleVisibility.for(nil).searching(term)

      assert_predicate @articles, :any?, "expected #{field} matches for #{term.inspect}"
    end
  end

  test "searching narrows to the requested fields" do
    articles = ArticleVisibility.for(nil).searching("test author", fields: %i[title intro tags])

    assert_empty articles, "expected the author field to be excluded when fields: omits it"
  end

  test "searching truncates an oversized term before it reaches SQL" do
    long_query = "a" * (ArticleVisibility::QUERY_LENGTH_LIMIT + 50)
    truncated = "a" * ArticleVisibility::QUERY_LENGTH_LIMIT

    queries = capture_queries { ArticleVisibility.for(nil).searching(long_query).to_a }

    main = queries.find { |q| q.include?('FROM "articles"') }
    assert_match(/ILIKE.*#{truncated}/, main,
      "expected the ILIKE pattern truncated to #{ArticleVisibility::QUERY_LENGTH_LIMIT} chars")
    assert_no_match(/ILIKE.*#{Regexp.escape(long_query)}/, main,
      "expected the oversized term to never reach SQL")
  end

  test "searching is a no-op without terms" do
    relation = ArticleVisibility.for(nil)

    assert_equal relation.to_a, relation.searching(nil).to_a
  end

  test "ordered_by supports the documented orderings" do
    feed = ArticleVisibility.for(nil)

    assert_equal feed.order_by_popularity.to_sql, feed.ordered_by(:popularity).to_sql
    assert_equal feed.order(published_at: :desc).to_sql, feed.ordered_by(:recent).to_sql
    assert_equal feed.order_by_revenue_usd.to_sql, feed.ordered_by(:revenue).to_sql
    assert_equal feed.order(created_at: :asc).to_sql, feed.ordered_by(:oldest).to_sql
    assert_equal feed.order(created_at: :desc).to_sql, feed.ordered_by(:newest).to_sql
  end

  test "ordered_by raises on an unknown ordering instead of silently falling back" do
    assert_raises(ArgumentError) { ArticleVisibility.for(nil).ordered_by(:cheapest) }
  end

  test "in_range narrows by published_at" do
    articles(:published_paid).update!(published_at: 2.weeks.ago)

    assert_includes ArticleVisibility.for(nil).in_range("week").map(&:uuid), articles(:high_revenue).uuid
    assert_not_includes ArticleVisibility.for(nil).in_range("week").map(&:uuid), articles(:published_paid).uuid
    assert_includes ArticleVisibility.for(nil).in_range("month").map(&:uuid), articles(:published_paid).uuid
    assert_equal ArticleVisibility.for(nil).to_a, ArticleVisibility.for(nil).in_range("decade").to_a
  ensure
    articles(:published_paid).update!(published_at: 3.days.ago)
  end

  test "subscribed_to inlines both halves as SQL subqueries" do
    reader = users(:reader_one)
    reader.create_action(:subscribe, target: users(:author))

    queries = capture_queries do
      @articles = ArticleVisibility.for(reader).subscribed_to(reader).to_a
    end

    assert_includes @articles.map(&:uuid), articles(:published_paid).uuid
    main = queries.find { |q| q.include?('FROM "articles"') }
    assert_operator main.scan(/IN\s*\(SELECT/i).size, :>=, 2,
      "expected subscribed_to to inline both predicates as SQL subqueries, got: #{main}"
  end

  test "bought_by returns nothing for a nil viewer" do
    assert_empty ArticleVisibility.for(nil).bought_by(nil).to_a
  end

  private

  def capture_queries
    queries = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end
end
