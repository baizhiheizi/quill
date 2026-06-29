# frozen_string_literal: true

require "test_helper"

# Covers the `Articles::Purchasable` concern shared by `Article` (and any
# future purchasable model that opts in via `include Articles::Purchasable`).
#
# Public surface tested:
#
# - `may_buy_by?(user = nil)` — gating predicate for the buy flow.
#   Returns false when the author has blocked the user, when the user
#   has blocked the author, or when the article is not published.
#   Returns true for nil users (the policy layer separately denies
#   unauthenticated buyers) and for the author on their own article
#   (the policy layer separately denies self-purchases).
#
# - `authorized?(user = nil)` — access check for paywalled content.
#   Always true on published free articles. Always true for the
#   author. Returns false for nil users on paid articles. Returns
#   true for users with a `buy_article` order on the article, or
#   whose collection grants access.
#
# Why a dedicated file: the existing `article_test.rb` only has six
# tests covering the happy paths of these two predicates. The branch
# coverage there is shallow (collection authorization, paid-but-
# non-buyer, free-article-on-paid) and never inspects the
# `published?` short-circuit when the author or user is blocked.
# This file pins the full decision table for both predicates.
class Articles::PurchasableTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @reader = users(:reader_one)
  end

  # --- may_buy_by? ---

  test "may_buy_by? returns true for a published article with no blocks" do
    article = articles(:published_paid)

    assert article.may_buy_by?
    assert article.may_buy_by?(@reader)
  end

  test "may_buy_by? returns true for nil user on a published article" do
    article = articles(:published_paid)

    # `user&.block_user?(author)` short-circuits to nil; `author.block_user?(nil)`
    # is false. may_buy_by? therefore returns `published?` for unauth callers.
    # The policy layer's `purchase?` separately requires `user.present?`.
    assert article.may_buy_by?(nil)
  end

  test "may_buy_by? returns true for the author on their own published article" do
    article = articles(:published_paid)

    # Note: the policy layer's `purchase?` separately denies this, but the
    # Purchasable concern's may_buy_by? only checks blocking + state.
    assert article.may_buy_by?(@author)
  end

  test "may_buy_by? returns true for a free published article" do
    article = articles(:published_free)

    assert article.may_buy_by?(@reader)
  end

  test "may_buy_by? returns false when the author has blocked the user" do
    article = articles(:published_paid)
    @author.block_user(@reader)

    assert_not article.may_buy_by?(@reader)
  end

  test "may_buy_by? returns false when the user has blocked the author" do
    article = articles(:published_paid)
    @reader.block_user(@author)

    assert_not article.may_buy_by?(@reader)
  end

  test "may_buy_by? returns false for an unpublished article even with no blocks" do
    article = articles(:draft)

    assert_not article.may_buy_by?(@reader)
    assert_not article.may_buy_by?(nil)
  end

  test "may_buy_by? ignores the block state when the article is not published" do
    article = articles(:draft)
    @author.block_user(@reader)
    @reader.block_user(@author)

    # published? is the final predicate, so blocks do not change the
    # outcome for a non-published article. The result is still false.
    assert_not article.may_buy_by?(@reader)
  end

  # --- authorized? ---

  test "authorized? returns true for a free published article for any caller" do
    article = articles(:published_free)

    assert article.authorized?
    assert article.authorized?(nil)
    assert article.authorized?(@reader)
  end

  test "authorized? returns true for the author of a paid article" do
    article = articles(:published_paid)

    assert article.authorized?(@author)
  end

  test "authorized? returns false for nil user on a paid article" do
    article = articles(:published_paid)

    assert_not article.authorized?(nil)
  end

  test "authorized? returns false for a stranger on a paid article" do
    article = articles(:published_paid)

    assert_not article.authorized?(@reader)
  end

  test "authorized? returns true for a buyer with a buy_article order" do
    article = articles(:published_paid)
    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: @reader)
    end

    assert article.authorized?(@reader)
  end

  test "authorized? returns false for a buyer whose only order is reward_article" do
    article = articles(:published_paid)
    with_quill_bot_stub do
      order = create_buy_order!(article: article, buyer: @reader)
      order.update!(order_type: :reward_article)
    end

    assert_not article.authorized?(@reader)
  end

  test "authorized? returns false for a non-published article even when free" do
    article = articles(:draft)
    article.update_columns(price: 0.0)
    article.reload

    # The published? short-circuit fires before free?; a non-published
    # free article is still unauthorized.
    assert_not article.authorized?
    assert_not article.authorized?(@reader)
  end

  test "authorized? does not consult the collection when the article has no collection" do
    article = Article.new
    assert_nil article.collection

    # No collection → collection&.authorized? short-circuits to nil → final
    # result is whatever the published/buyer path returns. An unpublished
    # article with no orders stays unauthorized.
    assert_not article.authorized?(@reader)
  end
end
