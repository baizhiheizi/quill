# frozen_string_literal: true

# Allow-list sanitizer for author-supplied HTML.
#
# ActionText only sanitizes a RichText when it is rendered through
# `ActionText::ContentHelper`; reading `body.to_html` directly - which both
# render pipelines did - returns the raw fragment. A `<script>` tag posted
# alongside an article therefore survived into every reader's page.
#
# The lists below are the union of what the editor can emit and what the
# render pipeline post-processes (tables, figures, YouTube iframes). Anything
# outside them is dropped together with its content, so a disallowed element
# (e.g. `<script>`) never reaches the page, not even as inert text.
#
# `iframe` is allowed here on purpose. `HtmlPostProcessor#escape_iframes`
# runs after this and removes every iframe whose src is not a YouTube URL,
# so the narrow per-source policy still lives in one place.
module HtmlSanitizer
  # Rails' SafeListSanitizer defaults, plus the block/inline elements the
  # editor and the post-processing pipeline rely on.
  ALLOWED_TAGS = %w[
    a abbr acronym address b big blockquote br cite code dd del dfn div dl dt em
    h1 h2 h3 h4 h5 h6 hr i img ins kbd li mark ol p pre samp small span strong
    sub sup time ul
    s strike u center
    table thead tbody tfoot tr td th caption colgroup col
    figure figcaption
    iframe video audio source track
  ].freeze

  # Rails' SafeListSanitizer defaults, plus the Turbo attributes and the
  # iframe/media attributes that `escape_iframes` and the post-processing
  # pipeline read. `data-turbo-method` is deliberately absent: it would let
  # author-supplied links issue state-changing requests (Turbo attaches the
  # CSRF token), so it is only ever added by the pipeline itself, after
  # sanitization.
  ALLOWED_ATTRIBUTES = %w[
    abbr alt cite class datetime height href lang name src title width xml:lang
    data-turbo-frame data-turbo-confirm
    allowfullscreen frameborder allow scrolling referrerpolicy
    controls poster
  ].freeze

  def self.call(html)
    return "" if html.blank?

    # `prune: true` drops a disallowed element together with its content, so
    # the body of a `<script>` or `<style>` never reaches the page as inert
    # text. The surrounding text of an inline script is kept.
    Rails::HTML4::Sanitizer.safe_list_sanitizer.new(prune: true).sanitize(
      html,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    )
  end
end
