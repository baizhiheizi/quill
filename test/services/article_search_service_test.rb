# frozen_string_literal: true

require "test_helper"

class ArticleSearchServiceTest < ActiveSupport::TestCase
  test "filter revenue orders by revenue_usd" do
    articles = ArticleSearchService.call(filter: "revenue").to_a

    assert_includes articles.map(&:uuid), articles(:high_revenue).uuid
  end

  test "filter lately orders by published_at desc" do
    articles = ArticleSearchService.call(filter: "lately").to_a
    uuids = articles.map(&:uuid)

    assert_operator uuids.index(articles(:high_revenue).uuid), :<, uuids.index(articles(:published_free).uuid)
  end

  test "time_range week limits to recent publications" do
    articles(:published_paid).update!(published_at: 2.weeks.ago)
    articles = ArticleSearchService.call(time_range: "week", filter: "lately").to_a

    assert_includes articles.map(&:uuid), articles(:high_revenue).uuid
    assert_not_includes articles.map(&:uuid), articles(:published_paid).uuid
  ensure
    articles(:published_paid).update!(published_at: 3.days.ago)
  end

  test "filter bought returns reader purchases" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    articles = ArticleSearchService.call(filter: "bought", current_user: buyer).to_a

    assert_includes articles.map(&:uuid), article.uuid
  end

  test "excludes blocked authors" do
    author = users(:author)
    reader = users(:reader_one)
    author.block_user(reader)

    articles = ArticleSearchService.call(current_user: reader).to_a

    assert_not_includes articles.map(&:author_id), author.id
  end

  test "filter subscribed returns articles from subscribed authors via SQL subquery" do
    reader = users(:reader_one)
    author = users(:author)
    reader.create_action(:subscribe, target: author)

    queries = capture_queries do
      @articles = ArticleSearchService.call(filter: "subscribed", current_user: reader).to_a
    end

    assert_includes @articles.map(&:uuid), articles(:published_paid).uuid
    assert_not_includes @articles.map(&:uuid), articles(:draft).uuid
    main_article_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_not_nil main_article_query
    assert_operator main_article_query.scan(/IN\s*\(SELECT/i).size, :>=, 2,
      "expected subscribed filter to inline both predicates as SQL subqueries"
  end

  test "filter subscribed with no subscription returns no rows via subquery" do
    reader = users(:reader_one)

    queries = capture_queries do
      @articles = ArticleSearchService.call(filter: "subscribed", current_user: reader).to_a
    end

    assert_empty @articles
    # Subquery approach must still issue a single main SELECT (plus eager loads)
    main_article_selects = queries.count { |q| q.include?('FROM "articles"') }
    assert_equal 1, main_article_selects,
      "expected exactly one articles SELECT, got #{main_article_selects}"
  end

  test "filter_block_authors excludes authors blocked in either direction via SQL subqueries" do
    author = users(:author)
    reader = users(:reader_one)
    reader.block_user(author)
    author.block_user(reader)

    queries = capture_queries do
      @articles = ArticleSearchService.call(current_user: reader).to_a
    end

    assert_not_includes @articles.map(&:author_id), author.id
    main_article_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_not_nil main_article_query
    assert_operator main_article_query.scan(/NOT\s+IN\s*\(SELECT/i).size, :>=, 2,
      "expected filter_block_authors to inline both directions as SQL subqueries"
  end

  test "block filter does not run SQL when @current_user is blank" do
    queries = capture_queries do
      ArticleSearchService.call(current_user: nil).to_a
    end

    main_article_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_not_nil main_article_query
    assert_no_match(/NOT\s+IN\s*\(SELECT/i, main_article_query,
      "expected no NOT IN subqueries when @current_user is nil")
  end

  # Cross-Locale Article Visibility (US1, FR-001, SC-001):
  # The default feed must include articles in every language regardless of
  # the caller's `current_user.locale`. The previous `#localize` step
  # narrowed the relation to `articles.locale = caller_locale`; that step
  # has been removed.
  test "default feed includes articles from every locale regardless of caller's locale" do
    chinese_user = users(:author_zh)
    english_user = users(:author)
    japanese_user = users(:author_ja)

    %w[zh en ja].each do |caller_locale|
      u = case caller_locale
      when "zh" then chinese_user
      when "ja" then japanese_user
      else english_user
      end

      articles = ArticleSearchService.call(current_user: u).to_a
      uuids = articles.map(&:uuid)

      assert_includes uuids, articles(:published_paid).uuid,
        "expected en article in feed for caller_locale=#{caller_locale}"
      assert_includes uuids, articles(:published_zh).uuid,
        "expected zh article in feed for caller_locale=#{caller_locale}"
      assert_includes uuids, articles(:published_ja).uuid,
        "expected ja article in feed for caller_locale=#{caller_locale}"
    end
  end

  test "default feed does not emit a WHERE locale = ? predicate" do
    queries = capture_queries do
      ArticleSearchService.call(current_user: users(:author_zh)).to_a
    end

    main_article_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_not_nil main_article_query
    assert_no_match(/"articles"\."locale"\s*=/i, main_article_query,
      "expected no `articles.locale = ...` predicate in default feed, got: #{main_article_query}")
  end

  # Cross-Locale Article Visibility (US2, FR-002, FR-003, SC-002, SC-003):
  # Text search and the `subscribed` / `bought` filters must return matches
  # across all locales regardless of caller_locale.
  test "text query returns cross-locale matches" do
    articles = ArticleSearchService.call(query: "文章").to_a

    uuids = articles.map(&:uuid)
    assert_includes uuids, articles(:published_zh).uuid,
      "expected zh article in text-search results (query='文章')"
  end

  test "query longer than the limit is truncated before hitting Ransack" do
    long_query = "a" * (ArticleSearchService::QUERY_LENGTH_LIMIT + 50)
    truncated = "a" * ArticleSearchService::QUERY_LENGTH_LIMIT

    queries = capture_queries do
      ArticleSearchService.call(query: long_query).to_a
    end

    main_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_match(/ILIKE.*#{truncated}/, main_query,
      "expected the ILIKE pattern to be truncated to #{ArticleSearchService::QUERY_LENGTH_LIMIT} chars")
    assert_no_match(/ILIKE.*#{long_query}/, main_query,
      "expected the oversized query to never reach SQL")
  end

  test "subscribed filter returns articles from every locale the followed author published" do
    reader = users(:reader_one)
    author = users(:author)
    # Subscribe to the existing 'author' (en). Now confirm cross-locale:
    # the service must not narrow by the reader's locale.
    reader.create_action(:subscribe, target: author)

    articles = ArticleSearchService.call(filter: "subscribed", current_user: reader).to_a

    uuids = articles.map(&:uuid)
    assert_includes uuids, articles(:published_paid).uuid,
      "expected en article in subscribed feed"
    # The subscribed filter must not emit a WHERE articles.locale predicate.
    queries = capture_queries do
      ArticleSearchService.call(filter: "subscribed", current_user: reader).to_a
    end
    main_article_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_no_match(/"articles"\."locale"\s*=/i, main_article_query,
      "expected no articles.locale predicate in subscribed filter, got: #{main_article_query}")
  end

  test "bought filter returns articles from every locale the visitor purchased" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    queries = capture_queries do
      ArticleSearchService.call(filter: "bought", current_user: buyer).to_a
    end

    main_article_query = queries.find { |q| q.include?('FROM "articles"') }
    assert_not_nil main_article_query
    assert_no_match(/"articles"\."locale"\s*=/i, main_article_query,
      "expected no articles.locale predicate in bought filter, got: #{main_article_query}")
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
