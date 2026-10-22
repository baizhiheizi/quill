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

  test "strips data-turbo-method so author links cannot change the request method" do
    html = HtmlSanitizer.call('<a href="/articles/1" data-turbo-method="delete">click</a>')

    refute_includes html, "data-turbo-method"
    assert_includes html, 'href="/articles/1"'
  end

  test "keeps the turbo attributes that cannot change the request method" do
    html = HtmlSanitizer.call(
      '<a href="/articles/1" data-turbo-frame="modal" data-turbo-confirm="sure?">click</a>'
    )

    assert_includes html, "data-turbo-frame"
    assert_includes html, "data-turbo-confirm"
  end

  test "iframe allow-list only accepts real youtube hosts" do
    allow_list = HtmlPostProcessor::IFRAME_SRC_WHITE_LIST_REGEX

    assert allow_list.any? { |regex| regex.match?("https://www.youtube.com/embed/abc") }
    assert allow_list.any? { |regex| regex.match?("https://youtube.com/embed/abc") }

    [ "https://wwwayoutube.com/pwn", "https://www-youtube.com/pwn", "https://wwwXyoutube.com/pwn" ].each do |src|
      assert allow_list.none? { |regex| regex.match?(src) }, "expected #{src} to be rejected"
    end
  end

  test "look-alike iframe hosts are removed by the render pipeline" do
    html = RichTextRenderService.call(
      '<iframe src="https://wwwayoutube.com/pwn"></iframe>',
      type: :default
    )

    refute_includes html, "wwwayoutube.com"
    refute_includes html, "<iframe"
  end

  test "real youtube iframes survive the render pipeline" do
    html = RichTextRenderService.call(
      '<iframe src="https://www.youtube.com/embed/abc"></iframe>',
      type: :default
    )

    assert_includes html, "youtube.com"
    assert_includes html, "<iframe"
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
