# frozen_string_literal: true

# Shared Nokogiri-based HTML post-processing helpers used by
# MarkdownRenderService and RichTextRenderService. Methods mutate
# @html in place and return `self` so they can be chained.
module HtmlPostProcessor
  # Allow-list of iframe src patterns kept by `escape_iframes`. Only
  # YouTube is currently trusted; everything else is stripped.
  IFRAME_SRC_WHITE_LIST_REGEX = [ %r{\Ahttps://(www.)?youtube\.com/\S+\z} ].freeze

  def parse_link
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("a").each do |a|
      a["target"] = "_blank" if a["data-turbo-method"].blank?
    end
    @html = doc.to_html

    self
  end

  def parse_paragraph
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("p").each do |p|
      p["class"] = "text-ellipsis overflow-x-hidden"
    end
    @html = doc.to_html

    self
  end

  def parse_table
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("table").each do |table|
      table["class"] = "min-width-max"
      table.wrap('<div class="overflow-x-scroll"></div>')
    end
    @html = doc.to_html

    self
  end

  def add_attributes_to_images
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("img").each do |img|
      src = img.attr("src")
      normalize_image_src(img, src)

      size = Rails.cache.fetch(img["src"]) do
        FastImage.size img["src"]
      end
      Rails.cache.delete(img["src"]) if size.blank?

      size ||= []

      img.wrap <<~TAG
        <a#{' '}
          class='photoswipe'#{' '}
          data-pswp-src='#{img['src']}'#{' '}
          data-pswp-width='#{size.first}'#{' '}
          data-pswp-height='#{size.last}'#{' '}
          href='#{img['src']}'#{' '}
          target='_blank'
        >
      TAG

      img["class"] = "max-w-full mx-auto bg-zinc-50"
      img["width"] = size.first if size.first.present?
      img["height"] = size.last if size.last.present?
      img["loading"] = "lazy"
    end
    @html = doc.to_html

    self
  end

  def add_scroll_to_comment_attributes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("a").each do |link|
      href = link.attr("href")
      if href&.match?(/\A#comment/)
        link["data-turbo-method"] = "post"
        link["href"] = "/view_modals?type=comment_form&quote_comment_id=#{href.underscore.split('_').last}"
      end
    end
    @html = doc.to_html

    self
  end

  def escape_iframes
    doc = Nokogiri::HTML.fragment(@html)
    doc.css("iframe").each do |iframe|
      iframe["class"] = "w-full h-auto"
      iframe.remove unless iframe["src"]&.match?(Regexp.union(IFRAME_SRC_WHITE_LIST_REGEX))
    end
    @html = doc.to_html

    self
  end

  # Hook for subclasses to rewrite an image's src before caching/fetching
  # the image dimensions. Default handles Active Storage blob URLs by
  # stripping trailing file extensions.
  def normalize_image_src(img, src)
    return if src.blank?

    if src.match?(%r{/rails/active_storage/blobs/\S+})
      img["src"] = src.gsub(/\.\S+\z/, "")
    end
  end
end
