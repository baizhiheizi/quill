# frozen_string_literal: true

require "test_helper"

class RichTextContentTest < ActiveSupport::TestCase
  test "content_as_html falls back to legacy markdown when action text is empty" do
    article = articles(:published_free)
    article.content.destroy
    article.reload
    article.update_column(:legacy_markdown_content, "**Hello** from legacy markdown")

    assert_not article.migrated_content?
    assert_includes article.content_as_html, "<strong>Hello</strong>"
    assert_equal "**Hello** from legacy markdown", article.plain_text
  end

  test "content_as_html prefers action text when migrated" do
    article = articles(:published_free)

    assert_includes article.content_as_html, "Free Article"
    assert_not_includes article.content_as_html, "legacy markdown"
  end

  test "published article validates with legacy markdown only" do
    article = articles(:published_free)
    article.content.destroy
    article.reload
    article.update_column(:legacy_markdown_content, "Legacy body for validation")

    assert article.valid?
  end

  test "comment content_as_html falls back to legacy markdown" do
    comment = Comment.create!(
      author: users(:reader_one),
      commentable: articles(:published_free),
      legacy_markdown_content: "Legacy *comment*"
    )

    assert_includes comment.content_as_html, "<em>comment</em>"
  end
end
