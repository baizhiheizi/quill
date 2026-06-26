# frozen_string_literal: true

require "test_helper"

class CreateTagServiceTest < ActiveSupport::TestCase
  setup do
    @article = articles(:published_paid)
  end

  # === Guard clauses ===

  test "no-op when tag_names is nil" do
    assert_no_difference -> { @article.taggings.count } do
      CreateTagService.call(@article, nil)
    end
  end

  test "no-op when tag_names is an empty array" do
    assert_no_difference -> { @article.taggings.count } do
      CreateTagService.call(@article, [])
    end
  end

  test "skips empty entries inside the tag_names array" do
    # compact_blank! drops blanks; the service does not treat this as
    # "remove everything". New tags get added, blanks are skipped.
    assert_difference -> { Tag.count }, 1 do
      CreateTagService.call(@article, [ "real-tag", nil, "", "   " ])
    end

    tag_names = Tag.where(name: "real-tag").pluck(:name)
    assert_equal [ "real-tag" ], tag_names
  end

  # === Adding new tags ===

  test "adds a single new tag and creates the tagging" do
    CreateTagService.call(@article, [ "newtag" ])

    tag = Tag.find_by(name: "newtag")
    assert tag, "Tag should have been created"
    assert_includes @article.reload.tags, tag
  end

  test "reuses existing tags instead of creating duplicates" do
    existing = Tag.create!(name: "existingtag")

    assert_no_difference -> { Tag.count } do
      CreateTagService.call(@article, [ "existingtag" ])
    end

    assert_includes @article.reload.tags, existing
  end

  test "strips whitespace from tag names when finding or creating" do
    CreateTagService.call(@article, [ "  padded  " ])

    tag = Tag.find_by(name: "padded")
    assert tag, "Tag should be created from the stripped name"
    assert_includes @article.reload.tags, tag
  end

  test "creates multiple taggings in a single call" do
    CreateTagService.call(@article, [ "alpha", "beta", "gamma" ])

    tag_names = @article.reload.tags.pluck(:name)
    assert_includes tag_names, "alpha"
    assert_includes tag_names, "beta"
    assert_includes tag_names, "gamma"
  end

  # === Removing tags ===

  test "removes taggings no longer in the tag list by default" do
    assert_includes @article.reload.tags, tags(:web3)

    CreateTagService.call(@article, [ "replacement" ])

    assert_not_includes @article.reload.tags, tags(:web3)
    assert_includes @article.reload.tags, Tag.find_by(name: "replacement")
  end

  test "removes only taggings absent from the new tag list" do
    other_tag = Tag.create!(name: "stay-attached")

    CreateTagService.call(@article, [ "stay-attached" ])

    assert_includes @article.reload.tags, other_tag
    assert_not_includes @article.reload.tags, tags(:web3)
  end

  test "with_remove: false leaves existing taggings intact" do
    CreateTagService.call(@article, [ "newtag" ], with_remove: false)

    assert_includes @article.reload.tags, tags(:web3)
    assert_includes @article.reload.tags, Tag.find_by(name: "newtag")
  end

  test "with_remove: false still adds new taggings" do
    assert_difference -> { @article.taggings.count }, 1 do
      CreateTagService.call(@article, [ "added-without-removal" ], with_remove: false)
    end
  end

  # === Idempotency ===

  test "running twice with the same names leaves the tagging count unchanged" do
    CreateTagService.call(@article, [ "stable" ])
    CreateTagService.call(@article, [ "stable" ])

    assert_equal 1, @article.reload.taggings.where(tag: Tag.find_by(name: "stable")).count
  end

  # === Counter cache ===

  test "increments tag articles_count when a new tagging is created" do
    tag = Tag.create!(name: "counter-test")

    CreateTagService.call(@article, [ "counter-test" ])

    assert_equal 1, tag.reload.articles_count
  end

  # === State on the article ===

  test "article.tags is reloaded after the call so the cache reflects the change" do
    CreateTagService.call(@article, [ "reloaded" ])

    # If `article.tags.reload` were not called, the association cache would
    # still return the previous set when accessed without reload.
    assert_includes @article.tags, Tag.find_by(name: "reloaded")
  end
end
