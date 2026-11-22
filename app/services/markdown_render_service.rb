# frozen_string_literal: true

class MarkdownRenderService
  include HtmlPostProcessor

  def initialize(content, **kargs)
    @content = content.to_s
    @type = kargs[:type] || :default
  end

  def self.call(*, **kargs)
    new(*, **kargs).call
  end

  def call
    @html = HtmlSanitizer.call(render_markdown)

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

  # Markdown mentions embed `blob://<key>/...` URLs in image tags so the
  # post-processor must look up the underlying ActiveStorage::Blob and
  # rewrite the src to a fetchable URL before the photoswipe wrapper
  # measures the image.
  def normalize_image_src(img, src)
    return if src.blank?

    case src
    when %r{/rails/active_storage/blobs/\S+}
      img["src"] = src.gsub(/\.\S+\z/, "")
    when %r{blob://\S+}
      key = src.gsub("blob://", "").split("/").first
      blob = ActiveStorage::Blob.find_by(key:)
      img["src"] = blob.url if blob.present?
    end
  end

  private

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
