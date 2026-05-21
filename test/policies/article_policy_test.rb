# frozen_string_literal: true

require "test_helper"

class ArticlePolicyTest < ActiveSupport::TestCase
  test "vote? allows authorized non-author readers" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    assert ArticlePolicy.new(buyer, article).vote?
  end

  test "vote? denies article author" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(article.author, article).vote?
  end

  test "comment? allows readers on published free articles" do
    article = articles(:published_free)
    reader = users(:reader_one)

    assert ArticlePolicy.new(reader, article).comment?
  end

  test "purchase? allows readers who have not bought the article" do
    article = articles(:published_paid)
    reader = users(:reader_one)

    assert ArticlePolicy.new(reader, article).purchase?
  end

  test "purchase? denies readers who already bought the article" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    refute ArticlePolicy.new(buyer, article).purchase?
  end

  test "reward? allows authorized readers" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    assert ArticlePolicy.new(buyer, article).reward?
  end
end
