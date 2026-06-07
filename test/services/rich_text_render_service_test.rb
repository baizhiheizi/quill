# frozen_string_literal: true

require "test_helper"

class RichTextRenderServiceTest < ActiveSupport::TestCase
  test "renders raw html input" do
    html = RichTextRenderService.call("<p>hi</p>", type: :default)

    assert_includes html, "<p>hi</p>"
  end

  test "default type escapes non-whitelisted iframes" do
    html = RichTextRenderService.call(
      '<iframe src="https://evil.example.com/x"></iframe>',
      type: :default
    )

    refute_includes html, "evil.example.com"
  end

  test "default type keeps whitelisted youtube iframes" do
    html = RichTextRenderService.call(
      '<iframe src="https://www.youtube.com/watch?v=abc"></iframe>',
      type: :default
    )

    assert_includes html, "youtube.com"
    assert_includes html, "w-full h-auto"
  end

  test "full type adds target=_blank to plain links" do
    html = RichTextRenderService.call(
      '<a href="https://example.com">x</a>',
      type: :full
    )

    assert_includes html, 'target="_blank"'
  end

  test "full type does not override existing data-turbo-method" do
    html = RichTextRenderService.call(
      '<a href="https://example.com" data-turbo-method="post">x</a>',
      type: :full
    )

    refute_includes html, 'target="_blank"'
  end

  test "full type adds text-ellipsis class to paragraphs" do
    html = RichTextRenderService.call("<p>hi</p>", type: :full)

    assert_match(/<p[^>]*class="text-ellipsis overflow-x-hidden"/, html)
  end

  test "full type wraps tables in overflow container" do
    html = RichTextRenderService.call(
      "<table><tr><td>a</td></tr></table>",
      type: :full
    )

    assert_includes html, "overflow-x-scroll"
    assert_match(/<table[^>]*class="min-width-max"/, html)
  end

  test "full type rewrites #comment_ links" do
    html = RichTextRenderService.call(
      '<a href="#comment_99">reply</a>',
      type: :full
    )

    assert_includes html, "/view_modals?type=comment_form"
    assert_includes html, "quote_comment_id=99"
    assert_includes html, 'data-turbo-method="post"'
  end

  test "full type strips non-whitelisted iframes" do
    html = RichTextRenderService.call(
      '<iframe src="https://malicious.test/x"></iframe>',
      type: :full
    )

    refute_includes html, "malicious.test"
  end

  test "full type wraps images in photoswipe anchor" do
    html = RichTextRenderService.call(
      '<img src="https://example.invalid/a.png" />',
      type: :full
    )

    assert_includes html, "photoswipe"
    assert_includes html, 'loading="lazy"'
  end

  test "full type removes extension from active storage blob URLs" do
    html = RichTextRenderService.call(
      '<img src="/rails/active_storage/blobs/xyz789.png" />',
      type: :full
    )

    refute_includes html, "xyz789.png"
  end

  test "class call shortcut returns rendered html" do
    assert_equal RichTextRenderService.new("<p>x</p>", type: :default).call,
                 RichTextRenderService.call("<p>x</p>", type: :default)
  end

  test "iframe with javascript scheme is stripped" do
    html = RichTextRenderService.call(
      '<iframe src="javascript:alert(1)"></iframe>',
      type: :default
    )

    refute_includes html, "javascript:"
  end

  test "coerces non-string input" do
    # to_s on nil is ""; the iframe scrubber then sees empty content.
    html = RichTextRenderService.call(nil, type: :default)

    assert_equal "", html
  end

  test "ActionText::Content is rendered through to_html" do
    content = ActionText::Content.new("<p>action text body</p>")
    html = RichTextRenderService.new(content, type: :default).call

    assert_includes html, "action text body"
  end

  test "unknown type leaves input untouched" do
    html = RichTextRenderService.call("<iframe src=\"https://evil.test\"></iframe>", type: :unknown)

    # No iframe escaping in unknown mode.
    assert_includes html, "evil.test"
  end

  test "default type applies the same iframe whitelist as markdown service" do
    assert_equal MarkdownRenderService::IFRAME_SRC_WHITE_LIST_REGEX,
                 RichTextRenderService::IFRAME_SRC_WHITE_LIST_REGEX
  end
end
