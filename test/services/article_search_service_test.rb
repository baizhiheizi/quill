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
