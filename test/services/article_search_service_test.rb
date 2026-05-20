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
end
