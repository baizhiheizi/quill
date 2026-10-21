# frozen_string_literal: true

require "test_helper"

class HtmlSanitizerTest < ActiveSupport::TestCase
  test "removes script tags" do
    html = HtmlSanitizer.call("<p>hi</p><script>alert(document.domain)</script>")

    refute_includes html, "<script"
    refute_includes html, "alert(document.domain)"
    assert_includes html, "<p>hi</p>"
  end

  test "removes event handler attributes" do
    html = HtmlSanitizer.call('<p onclick="alert(1)">hi</p>')

    refute_includes html, "onclick"
    assert_includes html, "hi"
  end

  test "removes javascript: urls" do
    html = HtmlSanitizer.call('<a href="javascript:alert(1)">x</a>')

    refute_includes html, "javascript:"
  end

  test "keeps the tags the render pipeline post-processes" do
    html = HtmlSanitizer.call(
      "<table><tr><td>a</td></tr></table><figure><figcaption>cap</figcaption></figure>"
    )

    assert_includes html, "<table>"
    assert_includes html, "<td>a</td>"
    assert_includes html, "<figure>"
    assert_includes html, "<figcaption>cap</figcaption>"
  end

  test "keeps iframes so escape_iframes can apply the per-source policy" do
    html = HtmlSanitizer.call('<iframe src="https://www.youtube.com/watch?v=abc"></iframe>')

    assert_includes html, "youtube.com"
  end

  test "keeps data-turbo-method so parse_link does not add target=_blank" do
    html = HtmlSanitizer.call('<a href="https://example.com" data-turbo-method="post">x</a>')

    assert_includes html, "data-turbo-method"
  end

  test "keeps class attributes" do
    html = HtmlSanitizer.call('<p class="lead">hi</p>')

    assert_includes html, "lead"
  end

  test "returns an empty string for blank input" do
    assert_equal "", HtmlSanitizer.call(nil)
    assert_equal "", HtmlSanitizer.call("")
  end
end
