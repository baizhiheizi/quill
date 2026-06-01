# frozen_string_literal: true

require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "authorized? allows free published articles for guests" do
    article = articles(:published_free)

    assert article.authorized?
    assert article.authorized?(nil)
  end

  test "authorized? allows author" do
    article = articles(:published_paid)
    user = users(:author)

    assert article.authorized?(user)
  end

  test "authorized? denies strangers on paid articles" do
    article = articles(:published_paid)

    assert_not article.authorized?(users(:reader_one))
  end

  test "authorized? allows buyer with buy order" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    assert article.authorized?(buyer)
  end

  test "may_buy_by? rejects blocked relationships" do
    article = articles(:published_paid)
    author = users(:author)
    reader = users(:reader_one)

    author.block_user(reader)

    assert_not article.may_buy_by?(reader)
  end

  test "may_buy_by? rejects unpublished articles" do
    article = articles(:draft)

    assert_not article.may_buy_by?(users(:reader_one))
  end

  test "share_of returns author ratio for author" do
    article = articles(:published_paid)

    assert_in_delta 0.5, article.share_of(users(:author)), 0.001
  end

  test "ensure_revenue_ratios_sum_to_one rejects invalid ratios" do
    article = articles(:published_paid)
    article.author_revenue_ratio = 0.9

    assert_not article.valid?
    assert_includes article.errors[:author_revenue_ratio], " incorrect"
  end

  test "partial_content returns nil for short content" do
    article = articles(:published_free)
    article.update!(content: "<p>Short</p>")

    assert_nil article.partial_content
  end

  test "random_readers returns at most limit distinct readers" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    readers = article.random_readers(1)

    assert_equal 1, readers.size
    assert_equal buyer, readers.first
  end
end
