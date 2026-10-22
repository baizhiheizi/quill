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

  test "content_body strips script tags from the action text body" do
    article = articles(:published_free)
    article.content.update!(
      body: "<p>hi</p><script>alert(document.domain)</script>"
    )

    refute_includes article.content_body, "<script"
    refute_includes article.content_body, "alert(document.domain)"
    assert_includes article.content_body, "<p>hi</p>"
  end

  test "content_body drops iframes that are not on the youtube allow-list" do
    article = articles(:published_free)
    article.content.update!(
      body: '<p>hi</p><iframe src="https://evil.example.com/x"></iframe>'
    )

    refute_includes article.content_body, "evil.example.com"
    refute_includes article.content_body, "<iframe"
    assert_includes article.content_body, "<p>hi</p>"
  end

  test "content_body keeps youtube iframes" do
    article = articles(:published_free)
    article.content.update!(
      body: '<iframe src="https://www.youtube.com/embed/abc"></iframe>'
    )

    assert_includes article.content_body, "youtube.com"
    assert_includes article.content_body, "<iframe"
  end
end
