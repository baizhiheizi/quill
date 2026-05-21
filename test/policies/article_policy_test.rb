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
end
