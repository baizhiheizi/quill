# frozen_string_literal: true

class MarkdownRenderService
  IFRAME_SRC_WHITE_LIST_REGEX = [ %r{\Ahttps://(www.)?youtube\.com/\S+\z} ].freeze

  include HtmlPostProcessor

  def initialize(content, **kargs)
    @content = content.to_s
    @type = kargs[:type] || :default
  end

  def self.call(*, **kargs)
    new(*, **kargs).call
  end

  def call
    @html = Kramdown::Document.new(@content, input: "GFM").to_html

    case @type
    when :default
      escape_iframes
    when :full
      parse_paragraph
        .parse_link
        .parse_table
        .add_attributes_to_images
        .parse_mention_user
        .add_scroll_to_comment_attributes
        .escape_iframes
    end

    @html
  end

  def parse_mention_user
    self
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
end
