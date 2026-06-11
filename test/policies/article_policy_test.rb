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

  # === show? edge cases ===

  test "show? allows free published articles for guests" do
    article = articles(:published_free)

    assert ArticlePolicy.new(nil, article).show?
  end

  test "show? allows guests to preview paid published articles" do
    article = articles(:published_paid)

    assert ArticlePolicy.new(nil, article).show?
  end

  test "show? allows paid articles for buyers" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    assert ArticlePolicy.new(buyer, article).show?
  end

  test "show? allows paid articles for the author" do
    article = articles(:published_paid)

    assert ArticlePolicy.new(article.author, article).show?
  end

  test "show? denies draft articles" do
    article = articles(:draft)

    refute ArticlePolicy.new(users(:reader_one), article).show?
    refute ArticlePolicy.new(article.author, article).show?
  end

  test "show? denies users blocked by the author" do
    article = articles(:published_paid)
    reader = users(:reader_one)
    article.author.block_user(reader)

    refute ArticlePolicy.new(reader, article).show?
  end

  # === purchase? edge cases ===

  test "purchase? denies the author buying their own article" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(article.author, article).purchase?
  end

  test "purchase? denies guest users" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(nil, article).purchase?
  end

  test "purchase? denies users blocked by the author" do
    article = articles(:published_paid)
    reader = users(:reader_one)
    article.author.block_user(reader)

    refute ArticlePolicy.new(reader, article).purchase?
  end

  test "purchase? denies users who block the author" do
    article = articles(:published_paid)
    reader = users(:reader_one)
    reader.block_user(article.author)

    refute ArticlePolicy.new(reader, article).purchase?
  end

  test "purchase? denies draft articles" do
    article = articles(:draft)
    reader = users(:reader_one)

    refute ArticlePolicy.new(reader, article).purchase?
  end

  # === vote? edge cases ===

  test "vote? denies guest users" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(nil, article).vote?
  end

  test "vote? allows any logged-in user on a free article" do
    article = articles(:published_free)
    reader = users(:reader_one)

    assert ArticlePolicy.new(reader, article).vote?
  end

  test "vote? denies paid non-buyers" do
    article = articles(:published_paid)
    reader = users(:reader_one)

    refute ArticlePolicy.new(reader, article).vote?
  end

  test "vote? denies the article author" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(article.author, article).vote?
  end

  # === comment? edge cases ===

  test "comment? denies guest users on free articles" do
    article = articles(:published_free)

    refute ArticlePolicy.new(nil, article).comment?
  end

  test "comment? allows the author to comment on their own article" do
    article = articles(:published_paid)

    assert ArticlePolicy.new(article.author, article).comment?
  end

  test "comment? allows any logged-in user on a published free article" do
    article = articles(:published_free)
    reader = users(:reader_one)

    assert ArticlePolicy.new(reader, article).comment?
  end

  # === subscribe? edge cases ===

  test "subscribe? denies guest users" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(nil, article).subscribe?
  end

  test "subscribe? denies the author subscribing to their own article" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(article.author, article).subscribe?
  end

  # === reward? edge cases ===

  test "reward? denies paid non-buyers" do
    article = articles(:published_paid)
    reader = users(:reader_one)

    refute ArticlePolicy.new(reader, article).reward?
  end

  test "reward? allows the author to reward their own article" do
    # Policy does not exclude the author — the reward flow's own validation
    # is the gatekeeper. This test pins the policy behavior as it stands.
    article = articles(:published_paid)

    assert ArticlePolicy.new(article.author, article).reward?
  end

  # === update? edge cases ===

  test "update? denies non-authors" do
    article = articles(:published_paid)
    reader = users(:reader_one)

    refute ArticlePolicy.new(reader, article).update?
  end

  test "update? denies guest users" do
    article = articles(:published_paid)

    refute ArticlePolicy.new(nil, article).update?
  end
end
