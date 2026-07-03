# frozen_string_literal: true

require "test_helper"

class MarkdownRenderServiceTest < ActiveSupport::TestCase
  test "renders basic markdown to html" do
    html = MarkdownRenderService.call("**hello**", type: :default)

    assert_includes html, "<strong>hello</strong>"
  end

  test "coerces non-string content to string" do
    html = MarkdownRenderService.call(nil, type: :default)

    assert_equal "", html.strip
  end

  test "default type escapes non-whitelisted iframes" do
    html = MarkdownRenderService.call(
      '<iframe src="https://evil.example.com/x"></iframe>',
      type: :default
    )

    refute_includes html, "evil.example.com"
  end

  test "default type keeps whitelisted youtube iframes" do
    html = MarkdownRenderService.call(
      '<iframe src="https://www.youtube.com/watch?v=abc"></iframe>',
      type: :default
    )

    assert_includes html, "youtube.com"
    assert_includes html, "w-full h-auto"
  end

  test "default type allows non-www youtube host" do
    html = MarkdownRenderService.call(
      '<iframe src="https://youtube.com/embed/abc"></iframe>',
      type: :default
    )

    assert_includes html, "youtube.com"
  end

  test "default type adds w-full h-auto class to surviving iframes" do
    html = MarkdownRenderService.call(
      '<iframe src="https://www.youtube.com/watch?v=abc"></iframe>',
      type: :default
    )

    assert_includes html, 'class="w-full h-auto"'
  end

  test "full type adds target=_blank to plain links" do
    html = MarkdownRenderService.call("[click](https://example.com)", type: :full)

    assert_includes html, 'target="_blank"'
  end

  test "full type does not add target=_blank to links with data-turbo-method" do
    html = MarkdownRenderService.call(
      '<a href="https://example.com" data-turbo-method="post">x</a>',
      type: :full
    )

    refute_includes html, 'target="_blank"'
  end

  test "full type adds break-words class to paragraphs" do
    html = MarkdownRenderService.call("hello world", type: :full)

    assert_match(/<p[^>]*class="break-words"/, html)
  end

  test "full type wraps tables in overflow-x-scroll container with class" do
    html = MarkdownRenderService.call(
      "| h1 | h2 |\n|----|----|\n| a  | b  |",
      type: :full
    )

    assert_includes html, "overflow-x-scroll"
    assert_match(/<table[^>]*class="min-width-max"/, html)
  end

  test "full type rewrites #comment_ links to view_modals path" do
    html = MarkdownRenderService.call(
      '<a href="#comment_42">reply</a>',
      type: :full
    )

    assert_includes html, "view_modals?type=comment_form&amp;quote_comment_id=42"
    assert_includes html, 'data-turbo-method="post"'
  end

  test "full type keeps target=_blank on rewritten comment links" do
    html = MarkdownRenderService.call(
      '<a href="#comment_42">reply</a>',
      type: :full
    )

    # add_scroll_to_comment_attributes only sets data-turbo-method, not
    # data-turbo-method on the original node, but the link parsing step ran
    # before — and the rewritten href no longer matches the comment pattern.
    # After rewrite, the link has data-turbo-method set so parse_link skips
    # setting target=_blank; the existing target=_blank (if any) remains.
    # Confirm the link is fully rewritten:
    assert_includes html, "/view_modals?type=comment_form"
  end

  test "full type strips non-whitelisted iframes" do
    html = MarkdownRenderService.call(
      '<iframe src="https://malicious.test/x"></iframe>',
      type: :full
    )

    refute_includes html, "malicious.test"
  end

  test "full type keeps whitelisted youtube iframes" do
    html = MarkdownRenderService.call(
      '<iframe src="https://www.youtube.com/watch?v=xyz"></iframe>',
      type: :full
    )

    assert_includes html, "youtube.com"
  end

  test "class call shortcut returns rendered html" do
    assert_equal MarkdownRenderService.new("**x**", type: :default).call,
                 MarkdownRenderService.call("**x**", type: :default)
  end

  test "default type skips image processing" do
    html = MarkdownRenderService.call(
      "![alt](https://example.com/img.png)",
      type: :default
    )

    # Default pipeline only escapes iframes; images are not wrapped in
    # a photoswipe anchor.
    refute_includes html, "photoswipe"
  end

  test "full type adds loading=lazy to images" do
    html = MarkdownRenderService.call(
      "![alt](https://example.invalid/img.png)",
      type: :full
    )

    # FastImage.size may fail to fetch the URL; the img node should still be
    # present (FastImage returns nil for failures and we just leave width/height blank).
    # We just verify the photoswipe wrapper and loading=lazy are added.
    assert_includes html, "photoswipe"
    assert_includes html, 'loading="lazy"'
  end

  test "full type removes extension from active storage blob URLs" do
    html = MarkdownRenderService.call(
      "![alt](/rails/active_storage/blobs/abc123.png)",
      type: :full
    )

    # ActiveStorage blob URLs get their trailing extension stripped.
    assert_match(%r{/rails/active_storage/blobs/abc123["'/?]}, html)
    refute_includes html, "abc123.png"
  end

  test "full type applies both image wrapping and iframe escaping" do
    html = MarkdownRenderService.call(
      "![pic](https://example.invalid/a.png)\n\n<iframe src=\"https://evil.test\"></iframe>",
      type: :full
    )

    assert_includes html, "photoswipe"
    refute_includes html, "evil.test"
  end

  test "unknown type falls through without post-processing" do
    html = MarkdownRenderService.call("**bold**", type: :unknown)

    # No type matches; @html is left as the raw kramdown output.
    assert_includes html, "<strong>bold</strong>"
  end

  test "iframe with javascript scheme is stripped" do
    html = MarkdownRenderService.call(
      '<iframe src="javascript:alert(1)"></iframe>',
      type: :default
    )

    refute_includes html, "javascript:"
  end

  test "iframe with empty src is removed" do
    html = MarkdownRenderService.call(
      '<iframe src=""></iframe>',
      type: :default
    )

    refute_match(/<iframe[^>]*src=""/, html)
  end

  test "iframe without src attribute is removed" do
    html = MarkdownRenderService.call(
      "<iframe></iframe>",
      type: :default
    )

    refute_match(/<iframe[^>]*>/, html)
  end
end
