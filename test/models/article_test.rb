# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
# Database name: primary
#
#  id                                  :bigint           not null, primary key
#  author_revenue_ratio                :float            default(0.5)
#  collection_revenue_ratio            :float            default(0.0)
#  commenting_subscribers_count        :integer          default(0)
#  comments_count                      :integer          default(0), not null
#  downvotes_count                     :integer          default(0)
#  free_content_ratio                  :float            default(0.1)
#  intro                               :string
#  legacy_markdown_content             :text
#  locale                              :string
#  orders_count                        :integer          default(0), not null
#  platform_revenue_ratio              :float            default(0.1)
#  price                               :decimal(, )      not null
#  published_at                        :datetime
#  readers_revenue_ratio               :float            default(0.4)
#  references_revenue_ratio            :float            default(0.0)
#  revenue_btc                         :decimal(, )      default(0.0)
#  revenue_usd                         :decimal(, )      default(0.0)
#  source                              :string
#  state                               :string
#  tags_count                          :integer          default(0)
#  title                               :string
#  upvotes_count                       :integer          default(0)
#  uuid                                :uuid
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  asset_id(asset_id in Mixin Network) :uuid
#  author_id                           :bigint
#  collection_id                       :uuid
#
# Indexes
#
#  index_articles_on_asset_id       (asset_id)
#  index_articles_on_author_id      (author_id)
#  index_articles_on_collection_id  (collection_id)
#  index_articles_on_uuid           (uuid) UNIQUE
#
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

  test "may_buy_by? rejects when the reader blocks the author" do
    article = articles(:published_paid)
    reader = users(:reader_one)
    reader.block_user(article.author)

    assert_not article.may_buy_by?(reader)
  end

  test "may_buy_by? allows the author on their own published article" do
    article = articles(:published_paid)

    # Note: the policy layer's `purchase?` separately denies this, but the
    # Purchasable concern's may_buy_by? only checks blocking + state.
    assert article.may_buy_by?(article.author)
  end

  test "may_buy_by? returns true for nil user on a published article" do
    article = articles(:published_paid)

    # `user&.block_user?(author)` short-circuits to nil; `author.block_user?(nil)`
    # is false. may_buy_by? therefore returns `published?` for unauth callers.
    # The policy layer's `purchase?` separately requires `user.present?`.
    assert article.may_buy_by?(nil)
  end

  test "authorized? denies nil user on a paid article" do
    article = articles(:published_paid)

    assert_not article.authorized?(nil)
  end

  test "authorized? denies a free article that is not published" do
    article = articles(:draft)
    article.update_columns(price: 0.0)
    article.reload

    assert_not article.authorized?
    assert_not article.authorized?(users(:reader_one))
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

  test "order_by_popularity includes articles with no orders" do
    # Regression: INNER JOIN against orders excluded articles without any
    # purchases from the default feed. With LEFT JOIN + COALESCE they
    # should still appear (popularity = 0 via COALESCE).
    article = articles(:published_free)
    assert_equal 0, article.orders.count, "fixture precondition: no orders"

    result = Article.order_by_popularity.where(id: article.id)

    assert_includes result.to_a, article
    assert_equal 0, result.first.attributes["popularity"]
  end
end
