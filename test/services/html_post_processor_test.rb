# frozen_string_literal: true

require "test_helper"

# Direct contract tests for `HtmlPostProcessor`, the shared Nokogiri
# post-processing module included by MarkdownRenderService and
# RichTextRenderService. The two render services exercise the module end
# to end, but a few of its transforms - most notably
# `add_scroll_to_comment_attributes` - are never asserted on directly,
# and the chaining contract (mutate in place, return self, serialize once
# at the end) is only implicit in the callers.
class HtmlPostProcessorTest < ActiveSupport::TestCase
  # Minimal harness mirroring the render services: the module mutates
  # `@html` in place and serializes once at the end of the chain.
  class Processor
    include HtmlPostProcessor

    def initialize(html)
      @html = html
    end
  end

  def process(html)
    processor = Processor.new(html)
    yield processor
    processor.serialize!
  end

  test "parse_link opens plain links in a new tab" do
    html = process('<a href="https://example.com">x</a>') { |p| p.parse_link }

    assert_includes html, 'target="_blank"'
  end

  test "parse_link leaves a Turbo-driven link alone" do
    html = process('<a href="https://example.com" data-turbo-method="post">x</a>') { |p| p.parse_link }

    refute_includes html, 'target="_blank"'
  end

  test "parse_paragraph adds the break-words class" do
    html = process("<p>hi</p>") { |p| p.parse_paragraph }

    assert_match(/<p[^>]*class="break-words"/, html)
  end

  test "parse_table wraps the table in a horizontal scroll container" do
    html = process("<table><tr><td>a</td></tr></table>") { |p| p.parse_table }

    assert_includes html, "overflow-x-scroll"
    assert_includes html, "min-width-max"
  end

  test "add_scroll_to_comment_attributes rewrites a comment anchor into a quote form" do
    html = process('<a href="#comment_123">quote</a>') { |p| p.add_scroll_to_comment_attributes }

    assert_includes html, 'data-turbo-method="post"'
    assert_includes html, "view_modals?type=comment_form&amp;quote_comment_id=123"
  end

  test "add_scroll_to_comment_attributes leaves ordinary anchors alone" do
    html = process('<a href="https://example.com">x</a>') { |p| p.add_scroll_to_comment_attributes }

    refute_includes html, "view_modals"
    refute_includes html, "data-turbo-method"
  end

  test "escape_iframes removes an iframe that is not on the allow-list" do
    html = process('<iframe src="https://evil.example.com/x"></iframe>') { |p| p.escape_iframes }

    refute_includes html, "evil.example.com"
    refute_includes html, "<iframe"
  end

  test "escape_iframes keeps an allow-listed YouTube iframe" do
    html = process('<iframe src="https://www.youtube.com/watch?v=abc"></iframe>') { |p| p.escape_iframes }

    assert_includes html, "youtube.com"
    assert_includes html, "w-full h-auto"
  end

  test "escape_iframes removes a look-alike host that only starts with the allowed one" do
    html = process('<iframe src="https://youtube.com.evil.example.com/watch"></iframe>') { |p| p.escape_iframes }

    refute_includes html, "<iframe"
  end

  test "every transform returns self so the calls can be chained" do
    processor = Processor.new("<p>hi</p>")

    assert_same processor, processor.parse_paragraph
    assert_same processor, processor.parse_link
    assert_same processor, processor.parse_table
    assert_same processor, processor.add_scroll_to_comment_attributes
    assert_same processor, processor.escape_iframes
  end

  test "serialize! returns the serialized html rather than the processor" do
    processor = Processor.new("<p>hi</p>")

    assert_equal "<p>hi</p>", processor.serialize!
  end

  test "serialize! persists the accumulated mutations to the html" do
    processor = Processor.new("<p>hi</p>")

    processor.parse_paragraph

    assert_match(/<p[^>]*class="break-words"/, processor.serialize!)
  end

  test "serialize! is idempotent once the document has been written out" do
    processor = Processor.new("<p>hi</p>")

    processor.parse_paragraph
    first = processor.serialize!
    second = processor.serialize!

    assert_equal first, second
  end

  test "normalize_image_src strips the file extension from an Active Storage blob url" do
    processor = Processor.new("")
    img = Nokogiri::HTML.fragment('<img src="/rails/active_storage/blobs/abc123.png">').css("img").first

    processor.normalize_image_src(img, img["src"])

    assert_equal "/rails/active_storage/blobs/abc123", img["src"]
  end

  test "normalize_image_src leaves a blob url without an extension untouched" do
    processor = Processor.new("")
    img = Nokogiri::HTML.fragment('<img src="/rails/active_storage/blobs/abc123">').css("img").first

    processor.normalize_image_src(img, img["src"])

    assert_equal "/rails/active_storage/blobs/abc123", img["src"]
  end
end
