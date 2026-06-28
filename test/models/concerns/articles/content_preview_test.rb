# frozen_string_literal: true

require "test_helper"

# Covers `Articles::ContentPreview` — text-fragment extraction + upvote-ratio
# helpers shared by Article. Three families of method:
#
# 1. **Plain-text shaping** (`words_count`, `partial_content`, `default_intro`)
#    — operate on `plain_text` (Action Text strip or legacy markdown) and
#    the per-article `free_content_ratio`.
# 2. **HTML fragment shaping** (`partial_content_as_html`, `extract_html`)
#    — walk Nokogiri children of `content_as_html` and truncate at the
#    ratio-derived word position so the paywall preview stays well-formed.
# 3. **Engagement signal** (`upvote_ratio`) — integer percent of upvotes
#    against total votes, nil when there are none.
#
# `extract_html` is a public pure function. Its `case child` branch only
# handles `Nokogiri::XML::NodeSet` and `Nokogiri::XML::Text`; when a direct
# child is an Element (e.g. `<p>`), no truncation occurs — the element is
# emitted whole. The tests pin this current contract.
class Articles::ContentPreviewTest < ActiveSupport::TestCase
  # --- `words_count` -------------------------------------------------------

  test "words_count counts whitespace-separated tokens in plain text" do
    article = articles(:published_free)
    article.content.destroy
    article.reload
    article.update_column(:legacy_markdown_content, "hello world")

    assert_equal 2, article.words_count
  end

  test "words_count splits non-whitespace runs into single-char matches" do
    # The regex `/[a-zA-Z]+|\S/` matches each non-whitespace run as one
    # token even when it's punctuation. Two words + two punctuation marks
    # collapse to four tokens.
    article = articles(:published_free)
    article.content.destroy
    article.reload
    article.update_column(:legacy_markdown_content, "hi, there.")

    assert_equal 4, article.words_count
  end

  test "words_count is memoized on the instance" do
    article = articles(:published_free)
    article.content.destroy
    article.reload
    article.update_column(:legacy_markdown_content, "alpha beta")

    first = article.words_count
    second = article.words_count

    assert_same first, second
  end

  # --- `partial_content` ---------------------------------------------------

  test "partial_content returns nil when there are fewer than 300 words" do
    article = articles(:published_paid)

    assert_operator article.words_count, :<, 300,
                    "fixture precondition: paid article is below the 300-word paywall threshold"
    assert_nil article.partial_content
  end

  test "partial_content returns nil when free_content_ratio is zero" do
    article = long_content_article
    article.update_column(:free_content_ratio, 0.0)

    assert_nil article.partial_content
  end

  test "partial_content truncates plain_text to the ratio-derived word count" do
    article = long_content_article
    article.update_column(:free_content_ratio, 0.5)

    expected_words = (article.words_count * 0.5).to_i
    expected_text = article.plain_text.truncate(expected_words)

    assert_equal expected_text, article.partial_content
  end

  # --- `partial_content_as_html` ------------------------------------------

  test "partial_content_as_html returns an empty string when free_content_ratio is zero" do
    article = long_content_article
    article.update_column(:free_content_ratio, 0.0)

    assert_equal "", article.partial_content_as_html
  end

  test "partial_content_as_html returns an HTML fragment for a non-zero ratio" do
    article = long_content_article
    article.update_column(:free_content_ratio, 0.25)

    fragment = article.partial_content_as_html

    parsed = Nokogiri::HTML.fragment(fragment)
    assert_predicate parsed.errors, :empty?,
                     "expected no Nokogiri parse errors, got: #{parsed.errors.inspect}"
    assert_not_empty parsed.to_html
  end

  test "partial_content_as_html memoizes across calls" do
    article = long_content_article
    article.update_column(:free_content_ratio, 0.5)

    first = article.partial_content_as_html
    second = article.partial_content_as_html

    assert_same first, second,
                "@partial_content_as_html memoization should return the same object"
  end

  # --- `extract_html` -----------------------------------------------------

  test "extract_html includes children whose text fits the remaining budget" do
    html = "<p>short paragraph</p><p>another one</p>"

    result = Article.new.extract_html(html, 1_000)

    assert_includes result, "<p>short paragraph</p>"
    assert_includes result, "<p>another one</p>"
  end

  test "extract_html appends empty child fragments to preserve structure" do
    # The first child fits; the second is whitespace-only with `to_s`
    # non-empty but child.text empty. The `child.to_s.empty?` branch is
    # the empty-passthrough, but the non-empty child.text with positive
    # remaining budget also matches. What we *do* pin: empty-tag children
    # do not get dropped from the layout.
    html = "<p>fits</p><i></i>"

    result = Article.new.extract_html(html, 100)

    assert_includes result, "<p>fits</p>"
    assert_includes result, "<i></i>"
  end

  test "extract_html truncates a Text child whose text exceeds the remaining budget" do
    # Bare text produces a Nokogiri::XML::Text as the fragment's only
    # child. 13 chars total, budget 8 → truncated to 8 chars (String#truncate
    # appends "..." so the visible prefix is 5 chars).
    html = "abcdefghijklm"

    result = Article.new.extract_html(html, 8)

    assert_operator result.length, :<=, 11,
                    "expected truncated Text to fit the 8-char budget, got: #{result.inspect}"
    assert_match(/\Aabcde/, result)
    assert_not_includes result, "ijklm"
  end

  test "extract_html emits Element children whole when their text exceeds the budget" do
    # When the direct child is an Element (not Text or NodeSet), the
    # `case` falls through with no truncation; the element is appended
    # verbatim and the count is still bumped to `length`. This pins the
    # current contract so a future refactor can catch the change.
    html = "<p>abcdefghijklm</p>"

    result = Article.new.extract_html(html, 8)

    assert_equal "<p>abcdefghijklm</p>", result,
                 "Element children are emitted whole; only Text/NodeSet children are truncated"
  end

  # --- `default_intro` ----------------------------------------------------

  test "default_intro returns plain_text unchanged when it is under 140 chars" do
    article = articles(:published_free)
    article.content.destroy
    article.reload
    article.update_column(:legacy_markdown_content, "Short intro body")

    assert_equal "Short intro body", article.default_intro
  end

  test "default_intro truncates plain_text to 140 characters" do
    article = articles(:published_paid)

    intro = article.default_intro

    assert_operator intro.length, :<=, 140
    assert_operator intro.length, :>, 0
  end

  # --- `upvote_ratio` -----------------------------------------------------

  test "upvote_ratio returns nil when both vote counts are zero" do
    article = articles(:published_paid)
    article.update_columns(upvotes_count: 0, downvotes_count: 0)

    assert_nil article.upvote_ratio
  end

  test "upvote_ratio formats integer percentages without decimals" do
    article = articles(:published_paid)
    article.update_columns(upvotes_count: 3, downvotes_count: 1)

    assert_equal "75%", article.upvote_ratio
  end

  test "upvote_ratio rounds half values using floor division" do
    # 1/(1+2) = 33.33...%; format('%.0f') floors to 33%.
    article = articles(:published_paid)
    article.update_columns(upvotes_count: 1, downvotes_count: 2)

    assert_equal "33%", article.upvote_ratio
  end

  private

  # Build an article whose Action Text body has well over 300 words so the
  # `partial_content` truncation branch fires. The free_content_ratio is set
  # explicitly by each test.
  def long_content_article
    article = articles(:published_paid)
    article.content.destroy
    article.reload

    sentence = "Lorem ipsum dolor sit amet. " # 5 words × 70 = 350 words.
    long_body = sentence * 70
    article.content.body = "<p>#{long_body}</p>"
    article.save!

    article
  end
end
