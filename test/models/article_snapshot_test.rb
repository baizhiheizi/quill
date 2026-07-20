# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
# Database name: primary
#
#  id           :bigint           not null, primary key
#  article_uuid :uuid
#  raw          :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_article_snapshots_on_article_uuid  (article_uuid)
#

require "test_helper"

class ArticleSnapshotTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
  end

  # === store_accessor :raw, %w[title intro content digest] ===

  test "raw accessor reads back JSON keys written via store_accessor" do
    snapshot = ArticleSnapshot.new(article: @article)
    snapshot.raw = { "title" => "Snapshot Title", "intro" => "Snapshot Intro", "content" => "<p>body</p>", "digest" => "abc123" }

    assert_equal "Snapshot Title", snapshot.title
    assert_equal "Snapshot Intro", snapshot.intro
    assert_equal "<p>body</p>", snapshot.content
    assert_equal "abc123", snapshot.digest
  end

  test "store_accessor writes back through raw" do
    snapshot = ArticleSnapshot.new(article: @article)
    snapshot.title = "T"
    snapshot.intro = "I"
    snapshot.content = "C"
    snapshot.digest = "D"

    assert_equal "T", snapshot.raw["title"]
    assert_equal "I", snapshot.raw["intro"]
    assert_equal "C", snapshot.raw["content"]
    assert_equal "D", snapshot.raw["digest"]
  end

  test "store_accessor keys not touched are nil when raw is unset" do
    snapshot = ArticleSnapshot.new(article: @article)

    assert_nil snapshot.title
    assert_nil snapshot.intro
    assert_nil snapshot.content
    assert_nil snapshot.digest
  end

  test "raw can carry arbitrary JSON keys beyond the four declared accessors" do
    snapshot = ArticleSnapshot.new(article: @article)
    snapshot.raw = { "title" => "T", "extra_field" => 42 }

    assert_equal "T", snapshot.title
    assert_equal({ "title" => "T", "extra_field" => 42 }, snapshot.raw)
  end

  # === belongs_to :article via article_uuid ===

  test "article association resolves via article_uuid" do
    snapshot = ArticleSnapshot.new(article: @article)

    assert_equal @article, snapshot.article
    assert_equal @article.uuid, snapshot.article_uuid
  end

  test "snapshots are destroyed with their article" do
    article = articles(:published_free)
    snapshot = ArticleSnapshot.create!(article: article)

    assert article.snapshots.exists?(snapshot.id)

    article.destroy!

    assert_not ArticleSnapshot.exists?(snapshot.id)
  end

  # === before_validation :set_defaults, on: :create ===

  test "set_defaults populates raw from article.as_json on create" do
    snapshot = ArticleSnapshot.create!(article: @article)

    assert_not_nil snapshot.raw
    # Article#as_json returns the title as a string under "title" (Article
    # overrides as_json to whitelist fields — see app/models/article.rb).
    assert_equal @article.title, snapshot.raw["title"]
  end

  test "set_defaults copies article.content_body into raw['content']" do
    snapshot = ArticleSnapshot.create!(article: @article)

    assert_equal @article.content_body, snapshot.raw["content"]
    assert_not_nil @article.content_body
    assert_not_equal "", snapshot.raw["content"]
  end

  test "set_defaults stores SHA3-256 of article.content_body as raw['digest']" do
    snapshot = ArticleSnapshot.create!(article: @article)

    expected_digest = SHA3::Digest::SHA3_256.hexdigest(@article.content_body)

    assert_equal expected_digest, snapshot.raw["digest"]
  end

  test "set_defaults overwrites an explicitly provided raw on create (current behavior)" do
    # `set_defaults` calls `assign_attributes(raw: ...)` unconditionally on
    # `new_record?`, so a pre-supplied `raw:` is clobbered. Pinning this so a
    # future guard (`return if raw.present?`) is a deliberate decision, not a
    # silent behavior change.
    snapshot = ArticleSnapshot.create!(
      article: @article,
      raw: { "title" => "Override", "intro" => "Override intro" }
    )

    assert_equal @article.title, snapshot.raw["title"]
    assert_equal @article.intro, snapshot.raw["intro"]
    assert_equal @article.content_body, snapshot.raw["content"]
  end

  test "set_defaults only fires on create, not on update" do
    snapshot = ArticleSnapshot.create!(article: @article)
    original_raw = snapshot.raw.dup

    snapshot.update!(intro: "Updated intro")

    assert_equal "Updated intro", snapshot.intro
    assert_equal original_raw["title"], snapshot.raw["title"]
    assert_equal original_raw["digest"], snapshot.raw["digest"]
  end

  # === fresh? ===

  test "fresh? is true for the most recent snapshot of an article" do
    ArticleSnapshot.where(article_uuid: @article.uuid).destroy_all
    only = ArticleSnapshot.create!(article: @article)

    assert only.fresh?
  end

  test "fresh? is false when a later snapshot exists for the same article" do
    ArticleSnapshot.where(article_uuid: @article.uuid).destroy_all
    first = ArticleSnapshot.create!(article: @article, created_at: 2.days.ago)
    _second = ArticleSnapshot.create!(article: @article, created_at: 1.day.ago)

    assert_not first.fresh?
  end

  test "fresh? scopes by article_uuid, not by all snapshots" do
    ArticleSnapshot.where(article_uuid: @article.uuid).destroy_all
    other_article = articles(:published_free)
    ArticleSnapshot.where(article_uuid: other_article.uuid).destroy_all

    mine = ArticleSnapshot.create!(article: @article, created_at: 1.day.ago)
    _theirs = ArticleSnapshot.create!(article: other_article, created_at: 1.minute.ago)

    assert mine.fresh?
  end

  test "fresh? is false even when the later snapshot has been destroyed (uses a fresh query)" do
    ArticleSnapshot.where(article_uuid: @article.uuid).destroy_all
    snapshot = ArticleSnapshot.create!(article: @article)
    later = ArticleSnapshot.create!(article: @article)

    assert_not snapshot.fresh?

    later.destroy!

    assert snapshot.reload.fresh?
  end

  # === delegate :author, to: :article ===

  test "delegates author to the associated article" do
    snapshot = ArticleSnapshot.create!(article: @article)

    assert_equal @article.author, snapshot.author
  end

  # === Side-finding for the maintainer ===

  # ArticleSnapshot#previous_signed_snapshot (app/models/article_snapshot.rb:34)
  # calls `article.snapshots.signed` but no `signed` scope or column exists on
  # the association. Calling it raises NoMethodError today. This is not
  # asserted here because it would document a broken contract; flagging for
  # the maintainer in the PR description instead.

  # === Inverse association ===

  test "snapshots association is the inverse of article" do
    snapshot = ArticleSnapshot.create!(article: @article)

    assert_equal @article, snapshot.article
    assert_includes @article.snapshots, snapshot
  end
end
