# frozen_string_literal: true

class MarkdownRenderService
  include HtmlPostProcessor

  # `src="blob://<key>/<filename>"`, how the Markdown editor recorded uploads.
  BLOB_IMAGE_SRC = %r{src=(["'])blob://([^"'/]+)/[^"']*\1}

  def initialize(content, **kargs)
    @content = content.to_s
    @type = kargs[:type] || :default
  end

  def self.call(*, **kargs)
    new(*, **kargs).call
  end

  def call
    html = render_markdown
    html = resolve_blob_images(html) if @type == :full
    @html = HtmlSanitizer.call(html)

    case @type
    when :default
      escape_iframes
    when :full
      parse_paragraph
        .parse_link
        .parse_table
        .add_attributes_to_images
        .add_scroll_to_comment_attributes
        .escape_iframes
    end

    serialize!
  end

  private

  # The Markdown editor recorded an upload as `blob://<key>/<filename>` and
  # left resolving it to the blob's URL to render time. That has to happen
  # before sanitization: the sanitizer drops an `img[src]` whose scheme is not
  # on its allow-list and `blob` is not on it, so resolving after it turned
  # every legacy upload into a src-less `<img>`.
  #
  # Only the :full pipeline does this. `content_body` renders with :default
  # and is what an ArticleSnapshot digests, so its output is left as it is.
  def resolve_blob_images(html)
    keys = html.scan(BLOB_IMAGE_SRC).map { |_, key| key }.uniq
    return html if keys.empty?

    urls = ActiveStorage::Blob.where(key: keys).index_by(&:key).transform_values(&:url)

    html.gsub(BLOB_IMAGE_SRC) do
      matched = Regexp.last_match
      url = urls[matched[2]]
      url ? %(src="#{ERB::Util.html_escape(url)}") : matched[0]
    end
  end

  # kramdown >= 2.6.0 refuses to parse content nested deeper than 100 block
  # levels and raises Kramdown::Error, where 2.5.x rendered it fine.
  # Author-supplied Markdown reaches public pages, so degrade to sanitized
  # plain text instead of letting the error bubble up as a 500.
  def render_markdown
    Kramdown::Document.new(@content, input: "GFM").to_html
  rescue Kramdown::Error => e
    Rails.logger.warn("MarkdownRenderService fell back to plain text: #{e.message}")
    @content
  end
end
